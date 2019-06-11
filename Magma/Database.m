#import "Database.h"
#import <sqlite3.h>
#import "Source.h"

@implementation Database

static sqlite3 *magma_db;
static Database *sharedInstance;
static NSString *workingDirectory;

+ (instancetype)alloc {
	return sharedInstance ? nil : [super alloc];
}

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		if (!magma_db) {
			@throw [NSException
				exceptionWithName:NSGenericException
				reason:@"The working directory must be set before calling +[Database sharedInstance]."
				userInfo:nil
			];
		}
		sharedInstance = [self new];
		[sharedInstance startLoadingDataIfNeeded];
	}
	return sharedInstance;
}

+ (void)setWorkingDirectory:(NSString *)newLocation {
	BOOL isDir;
	if (![NSFileManager.defaultManager fileExistsAtPath:newLocation isDirectory:&isDir] || !isDir) {
		@throw [NSException
			exceptionWithName:NSInvalidArgumentException
			reason:@"The specified working directory doesn't exist."
			userInfo:nil
		];
	}
	if (sqlite3_open([newLocation stringByAppendingPathComponent:@"magma.db"].UTF8String, &magma_db) == SQLITE_OK) {
		int nextRepoID = [self nextIdentifierForTable:@"repositories" inSQLiteDatabase:magma_db];
		NSArray *queries = @[
#			if DEBUG
			@"DROP TABLE IF EXISTS `repositories`",
			@"DROP TABLE IF EXISTS `packages`",
#			endif
			@"CREATE TABLE IF NOT EXISTS `repositories` ("
			"  `id` INTEGER NOT NULL UNIQUE,"
			"  `base_url` TEXT NOT NULL,"
			"  `dist` TEXT NOT NULL,"
			"  `components` TEXT NOT NULL DEFAULT '',"
			"  `Release` TEXT NULL,"
			"  `last_refresh` REAL NULL,"
			"  PRIMARY KEY(`base_url`, `dist`, `components`)"
			")",
			@"CREATE TABLE IF NOT EXISTS `packages` ("
			"  `id` INTEGER NOT NULL UNIQUE,"
			"  `repo_id` INT NOT NULL,"
			"  `ignore_updates` INT NOT NULL DEFAULT 0,"
			"  `package` TEXT NOT NULL,"
			"  `version` TEXT NOT NULL,"
			"  `control` TEXT NOT NULL,"
			"  `first_discovery` REAL NOT NULL,"
			"  PRIMARY KEY(`repo_id`, `package`, `version`),"
			"  CONSTRAINT FK_repository FOREIGN KEY(`repo_id`) REFERENCES repositories(`id`) ON DELETE CASCADE"
			")",
			@"INSERT OR REPLACE INTO `repositories` ("
			"  `id`,"
			"  `base_url`,"
			"  `dist`"
			")"
			"VALUES ("
			"  -1," // Repositories with negative IDs are unremovable.
			"  'https://repo.pixelomer.com',"
			"  './'"
			")",
#			if DEBUG
			@"INSERT OR REPLACE INTO `repositories` ("
			"  `id`,"
			"  `base_url`,"
			"  `dist`"
			")"
			"VALUES ("
			"  ?,"
			"  'https://repo.nepeta.me',"
			"  './'"
			")"
#			endif
		];
		for (NSString *query in queries) {
			char *errorMessage;
			NSLog(@"%@", query);
			if (sqlite3_exec(magma_db, ([query containsString:@"?"] ? [query stringByReplacingOccurrencesOfString:@"?" withString:[NSString stringWithFormat:@"%d", nextRepoID++]] : query).UTF8String, NULL, NULL, &errorMessage) != SQLITE_OK) {
				@throw [NSException
					exceptionWithName:NSInternalInconsistencyException
					reason:[NSString stringWithFormat:@"sqlite3 Error: %s", errorMessage]
					userInfo:nil
				];
			}
			else NSLog(@"QUERY OK");
		}
	}
	else {
		@throw [NSException
			exceptionWithName:NSInternalInconsistencyException
			reason:@"Failed to open/create the sqlite3 database."
			userInfo:nil
		];
	}
	workingDirectory = newLocation.copy;
}

+ (NSString *)workingDirectory {
	return workingDirectory;
}

+ (int)nextIdentifierForTable:(NSString *)tableName inSQLiteDatabase:(sqlite3 *)db {
	sqlite3_stmt *statement;
	int nextID = 0;
	if (sqlite3_prepare_v2(db, [NSString stringWithFormat:@"SELECT MAX(`id`) FROM `%@`", tableName].UTF8String, -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			nextID = sqlite3_column_int(statement, 0) + 1;
		}
		sqlite3_finalize(statement);
	}
	else NSLog(@"%s", sqlite3_errmsg(magma_db));
	return nextID;
}

- (BOOL)isLoaded {
	return _isLoaded;
}

- (void)startLoadingDataIfNeeded {
	if (!_isLoaded) {
		if (!magma_db) {
			@throw [NSException
				exceptionWithName:NSInternalInconsistencyException
				reason:@"The sqlite3 database has to be opened before calling this method. Call +[Database setWorkingDirectory:] in order to do so."
				userInfo:nil
			];
		}
		// Load data from the filesystem
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			BOOL success = YES;
			sqlite3_stmt *statement;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpointer-sign"
			if (success = (sqlite3_prepare_v2(magma_db, "SELECT * FROM `repositories`", -1, &statement, NULL) == SQLITE_OK)) {
				NSMutableArray *rows = [NSMutableArray new];
				while (sqlite3_step(statement) == SQLITE_ROW) {
					int            repo_id = sqlite3_column_int(statement, 0);  // Unique
					const char   *base_url = sqlite3_column_text(statement, 1); // Composite Primary
					const char       *dist = sqlite3_column_text(statement, 2); // Composite Primary
					const char *components = sqlite3_column_text(statement, 3); // Composite Primary (can be an empty string)
					const char    *Release = sqlite3_column_text(statement, 4); // Full Release file, can be null
					BOOL       isBasicRepo = (!components || !*components);
					NSLog(@"Repo id: %d\nBase: %s\nDist: %s\nComponents: %s\nRelease: %s\nIs basic: %d", repo_id, base_url, dist, components, Release, isBasicRepo);
					//                 0           1            2        3            4                                     5
					[rows addObject:@[@(repo_id), @(base_url), @(dist), @(components), Release ? @(Release) : NSNull.null, @(isBasicRepo)]];
				}
				sqlite3_finalize(statement);
				for (NSArray *row in rows) {
					Source *source;
					if ([(NSNumber *)row[5] boolValue]) {
						source = [self addSourceWithURL:row[1] ID:row[0]];
					}
					else {
						source = [self addSourceWithBaseURL:row[1] distribution:row[2] components:row[3] ID:row[0]];
					}
					if (source) {
						if ([row[4] isKindOfClass:[NSString class]]) {
							source.rawReleaseFile = row[4];
						}
					}
				}
			}
#pragma GCC diagnostic pop
			_isLoaded = YES;
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidLoadNotification
				object:self
				userInfo:nil
			];
		});
	}
}

- (NSArray *)sources {
	return (id)[sources allValues];
}

- (void)removeSource:(Source *)source {
	sqlite3_stmt *statement;
	BOOL isSourceKnown = NO;
	NSArray<NSString *> *keys = sources.allKeys.copy;
	for (NSString *knownSourceIdentifier in keys) {
		Source *knownSource = sources[knownSourceIdentifier];
		if (knownSource == source) {
			[sources removeObjectForKey:knownSourceIdentifier];
			isSourceKnown = YES;
		}
	}
	BOOL success = YES;
	if (isSourceKnown && (success = (sqlite3_prepare_v2(magma_db, "DELETE FROM `repositories` WHERE `id`=?", -1, &statement, NULL) == SQLITE_OK))) {
		sqlite3_bind_int(statement, 1, source.databaseID);
		success = (sqlite3_step(statement) == SQLITE_DONE);
		sqlite3_finalize(statement);
	}
	if (!success) @throw [NSException
		exceptionWithName:NSInternalInconsistencyException
		reason:[NSString stringWithFormat:@"Failed to prepare the SQLite query to remove the specified source. This can cause the application to behave unexpectedly.\nSQLite Error: %s", sqlite3_errmsg(magma_db)]
		userInfo:nil
	];
}

- (Source *)addSourceWithURL:(NSString *)baseURL {
	return [self addSourceWithBaseURL:baseURL distribution:@"./" components:nil];
}

- (Source *)addSourceWithURL:(NSString *)baseURL ID:(NSNumber *)repoID {
	return [self addSourceWithBaseURL:baseURL distribution:@"./" components:nil ID:repoID];
}

- (Source *)addSourceWithBaseURL:(NSString *)baseURL distribution:(NSString *)dist components:(NSString *)components {
	return [self addSourceWithBaseURL:baseURL distribution:dist components:components ID:nil];
}

- (Source *)addSourceWithBaseURL:(NSString *)baseURL distribution:(NSString *)dist components:(NSString *)components ID:(NSNumber *)repoID {
	if (!sources) sources = [NSMutableDictionary new];
	Source *source = [[Source alloc] initWithBaseURL:baseURL distribution:dist components:components];
	if (source) {
		if (!sources[[source sourcesListEntryWithComponents:NO]]) {
			if (repoID) {
				// A repository ID was specified. The repository entry already exists in the database.
				source.databaseID = repoID.intValue;
			}
			else {
				// A repository ID wasn't specified. We need to add the repository entry ourselves.
				BOOL success = YES;
				int databaseID = [self.class nextIdentifierForTable:@"repositories" inSQLiteDatabase:magma_db];
				source.databaseID = databaseID;
				sqlite3_stmt *statement;
				if (success = (sqlite3_prepare_v2(magma_db, "INSERT OR REPLACE INTO `repositories` (`id`, `base_url`, `dist`, `components`) VALUES (?, ?, ?, ?)", -1, &statement, NULL) == SQLITE_OK)) {
					sqlite3_bind_int(statement, 1, databaseID);
					sqlite3_bind_text(statement, 2, source.baseURL.absoluteString.UTF8String);
					sqlite3_bind_text(statement, 3, source.distribution.UTF8String);
					sqlite3_bind_text(statement, 4, components.UTF8String ?: "");
					success = (sqlite3_step(statement) == SQLITE_DONE);
					sqlite3_finalize(statement);
				}
				if (!success) {
					NSLog(@"An SQLite error occurred while adding the source: %s", sqlite3_errmsg(magma_db));
					return nil;
				}
			}
			sources[[source sourcesListEntryWithComponents:NO]] = source;
			if (!repoID) {
				[NSNotificationCenter.defaultCenter
					postNotificationName:DatabaseDidAddSourceNotification
					object:self
					userInfo:@{ @"source" : source }
				];
			}
			return source;
		}
	}
	return nil;
}

@end
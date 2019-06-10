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
			reason:@"The specified directory doesn't exist."
			userInfo:nil
		];
	}
	if (sqlite3_open([newLocation stringByAppendingPathComponent:@"magma.db"].UTF8String, &magma_db) == SQLITE_OK) {
		NSArray *queries = @[
#			if DEBUG
			@"DROP TABLE IF EXISTS `repositories`",
#			endif
			@"CREATE TABLE IF NOT EXISTS `repositories` ("
			"	`id` INTEGER NOT NULL UNIQUE,"
			"	`base_url` TEXT NOT NULL,"
			"	`dist` TEXT NOT NULL,"
			"	`components` TEXT NOT NULL DEFAULT '',"
			"	`Release` TEXT NULL,"
			"	`last_refresh` DATETIME NULL,"
			"	PRIMARY KEY(`base_url`, `dist`, `components`)"
			")",
			@"CREATE TABLE IF NOT EXISTS `packages` ("
			"	`id` INTEGER NOT NULL UNIQUE,"
			"	`repo_id` INT NOT NULL,"
			"	`ignore_updates` INT NOT NULL DEFAULT 0,"
			"	`package` TEXT NOT NULL,"
			"	`version` TEXT NOT NULL,"
			"	`control` TEXT NOT NULL,"
			"	PRIMARY KEY(`repo_id`, `package`, `version`),"
			"	CONSTRAINT FK_repository FOREIGN KEY(`repo_id`) REFERENCES repositories(`id`) ON DELETE CASCADE"
			")",
#			if DEBUG
			@"INSERT OR REPLACE INTO `repositories` ("
			"	`id`,"
			"	`base_url`,"
			"	`dist`"
			")"
			"VALUES ("
			"	RANDOM(),"
			"	'https://repo.pixelomer.com',"
			"	'./'"
			")",
			@"INSERT OR REPLACE INTO `repositories` ("
			"	`id`,"
			"	`base_url`,"
			"	`dist`"
			")"
			"VALUES ("
			"	RANDOM(),"
			"	'https://repo.nepeta.me',"
			"	'./'"
			")"
#			endif
		];
		for (NSString *query in queries) {
			char *errorMessage;
			NSLog(@"%@", query);
			if (sqlite3_exec(magma_db, query.UTF8String, NULL, NULL, &errorMessage) != SQLITE_OK) {
				@throw [NSException
					exceptionWithName:NSInternalInconsistencyException
					reason:[NSString stringWithFormat:@"sqlite3 Error: %s", errorMessage]
					userInfo:nil
				];
			}
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
#define PrepareOrFail(query) (success = (sqlite3_prepare_v2(magma_db, query, -1, &statement, NULL) == SQLITE_OK))
			if (PrepareOrFail("SELECT * FROM `repositories`")) {
				while (sqlite3_step(statement) == SQLITE_ROW) {
					int            repo_id = sqlite3_column_int(statement, 0);  // Unique
					const char   *base_url = sqlite3_column_text(statement, 1); // Composite Primary
					const char       *dist = sqlite3_column_text(statement, 2); // Composite Primary
					const char *components = sqlite3_column_text(statement, 3); // Composite Primary (can be an empty string)
					const char    *Release = sqlite3_column_text(statement, 4); // Full Release file, can be null
					BOOL       isBasicRepo = (!components || !*components);
					NSLog(@"Repo id: %d\nBase: %s\nDist: %s\nComponents: %s\nRelease: %s\nIs basic: %d", repo_id, base_url, dist, components, Release, isBasicRepo);
					Source *source;
					if (isBasicRepo) {
						source = [self addSourceWithURL:@(base_url) ID:@(repo_id)];
					}
					else {
						source = [self addSourceWithBaseURL:@(base_url) distribution:@(dist) components:@(components) ID:@(repo_id)];
					}
					if (source) {
						if (Release) source.rawReleaseFile = @(Release);
					}
				}
				sqlite3_finalize(statement);
			}
#undef PrepareOrFail
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
	NSLog(@"call. repoID: %@, _isLoaded: %d", repoID, _isLoaded);
	if (!sources) sources = [NSMutableDictionary new];
	Source *source = [[Source alloc] initWithBaseURL:baseURL distribution:dist components:components];
	if (source) {
		if (!sources[[source sourcesListEntryWithComponents:NO]]) {
			NSLog(@"FIXME: A new row should be inserted here if _isLoaded is YES");
			source.databaseID = repoID.intValue;
			sources[[source sourcesListEntryWithComponents:NO]] = source;
			return source;
		}
	}
	return nil;
}

@end
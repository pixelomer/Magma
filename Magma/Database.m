#import "Database.h"
#import <sqlite3.h>

@implementation Database

static sqlite3 *magma_db;
static Database *sharedInstance;
static NSString *workingDirectory;

+ (instancetype)alloc {
	return sharedInstance ? nil : [super alloc];
}

+ (instancetype)sharedInstance {
	if (!sharedInstance) {
		sharedInstance = [self new];
		[sharedInstance startLoadingDataIfNeeded];
	}
	return sharedInstance;
}

+ (void)setWorkingDirectory:(NSString *)newLocation {
	if (sharedInstance) {
		@throw [NSException
			exceptionWithName:NSGenericException
			reason:@"The working directory must be set before calling +[Database sharedInstance]."
			userInfo:nil
		];
	}
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
			@"CREATE TABLE IF NOT EXISTS `repositories` ("
			"	`id` INT AUTO_INCREMENT NOT NULL UNIQUE,"
			"	`base_url` TEXT NOT NULL,"
			"	`dist` TEXT NOT NULL,"
			"	`components` TEXT NOT NULL,"
			"	`Release` TEXT NULL,"
			"	`last_refresh` DATETIME NULL,"
			"	PRIMARY KEY(`base_url`, `dist`, `components`)"
			")",
			@"CREATE TABLE IF NOT EXISTS `packages` ("
			"	`id` INT AUTO_INCREMENT NOT NULL UNIQUE,"
			"	`repo_id` INT NOT NULL,"
			"	`ignore_updates` INT NOT NULL DEFAULT 0,"
			"	`package` TEXT NOT NULL,"
			"	`version` TEXT NOT NULL,"
			"	`control` TEXT NOT NULL,"
			"	PRIMARY KEY(`repo_id`, `package`, `version`),"
			"	CONSTRAINT FK_repository FOREIGN KEY(`repo_id`) REFERENCES repositories(`id`) ON DELETE CASCADE"
			")"
		];
		for (NSString *query in queries) {
			char *errorMessage;
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
		// Load data from the filesystem
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			_isLoaded = YES;
			[NSNotificationCenter.defaultCenter
				postNotificationName:DatabaseDidLoadNotification
				object:self
				userInfo:nil
			];
		});
	}
}

@end
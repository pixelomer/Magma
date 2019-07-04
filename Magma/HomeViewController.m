#import "HomeViewController.h"

@implementation HomeViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = @"Home";
}

- (void)addMessageToQueue:(NSString *)message title:(NSString *)title {
	[(messageQueue = messageQueue ?: [NSMutableArray new]) addObject:@[message, title]];
	if (messageQueue.count == 1) [self presentNextMessageIfAvailable];
}

- (void)presentNextMessageIfAvailable {
	if (!isPresentingMessage && (messageQueue.count > 0)) {
		isPresentingMessage = YES;
		NSArray *messageArray = messageQueue[0];
		NSString *message = messageArray[0];
		NSString *title = messageArray[1];
		[messageQueue removeObjectAtIndex:0];
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction
			actionWithTitle:@"Dismiss"
			style:UIAlertActionStyleCancel
			handler:^(id action){
                self->isPresentingMessage = NO;
				dispatch_async(dispatch_get_main_queue(),^{
					[self presentNextMessageIfAvailable];
				});
			}
		]];
		[self.tabBarController presentViewController:alertController animated:YES completion:nil];
	}
}

- (void)didReceiveDatabaseNotification:(NSNotification *)notification {
	[super didReceiveDatabaseNotification:notification];
	if ([notification.name isEqualToString:DatabaseDidEncounterAnError]) {
		[self addMessageToQueue:notification.userInfo[@"error"] title:@"Database Error"];
	}
}

@end

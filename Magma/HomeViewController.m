#import "HomeViewController.h"
#import "FeaturedSourceCell.h"
#import "PreferencesViewController.h"
#import "AddSourceViewController.h"

@implementation HomeViewController

static NSArray<NSArray *> *defaultFeaturedSources; //Example: ( ("Section name", ( {...source A...}, {...source B...}, ... ), ... )

+ (void)load {
	if (self == [HomeViewController class]) {
		defaultFeaturedSources = @[
			@[@"Get Started", @[
				@{
					@"title" : @"Ubuntu",
					@"dists" : @{
						@"Cosmic (18.10)" : @"cosmic",
						@"Eoan (19.10)" : @"eoan",
						@"Disco (19.04)" : @"disco",
						@"Precise (12.04)" : @"precise",
						@"Trusty Tahr (14.04)" : @"trusty",
						@"Bionic Beaver (18.04)" : @"bionic",
						@"Xenial Xerus (16.04)" : @"xenial"
					},
					@"sections" : @{
						@"Main" : @"main",
						@"Universe" : @"universe",
						@"Restricted" : @"restricted",
						@"Multiverse" : @"multiverse"
					},
					@"description" : @"This is the default repository for the Ubuntu® operating system.",
					@"image" : @"Ubuntu",
					@"url" : @"http://archive.ubuntu.com/ubuntu",
					@"arch" : @"amd64"
				},
				@{
					@"title" : @"Debian",
					@"dists" : @{
						@"Buster (10.0)" : @"buster",
						@"Jessie (8.11)" : @"jessie",
						@"Stretch (9.9)" : @"stretch",
						@"Current Stable" : @"stable",
						@"Current Unstable" : @"unstable",
						@"Current Testing" : @"testing",
						@"Old Stable" : @"oldstable"
					},
					@"sections" : @{
						@"Main" : @"main",
						@"Contrib" : @"contrib",
						@"Non-free software" : @"non-free"
					},
					@"description" : @"This is the default repository for the Debian operating system.",
					@"image" : @"Debian",
					@"url" : @"https://deb.debian.org/debian",
					@"arch" : @"amd64"
				}
			]],
		];
	}
}

- (instancetype)init {
	if ((self = [super init])) {
		featuredSources = defaultFeaturedSources.copy; // Just in case I implement something in the future that allows me to modify this value remotely
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 15.0, 0.0, 15.0);
	self.tableView.tableFooterView = [UIView new];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
	self.title = @"Featured";
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	FeaturedSourceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (!cell && (cell = [[FeaturedSourceCell alloc] initWithReuseIdentifier:@"cell"])) {
		[cell.addSourceButton addTarget:self action:@selector(addSourceWithButton:) forControlEvents:UIControlEventTouchUpInside];
	}
	cell.infoDictionary = [(NSArray *)featuredSources[indexPath.section][1] objectAtIndex:indexPath.row];
	return cell;
}

- (void)addSourceWithButton:(AddFeaturedSourceButton *)button {
	AddSourceViewController *vc = [[AddSourceViewController alloc] initWithInformationDictionary:button.infoDictionary];
	vc.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:vc animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return featuredSources.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return featuredSources[section][0];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(NSArray *)featuredSources[section][1] count];
}

- (void)showSettings {
	PreferencesViewController *prefsVC = [PreferencesViewController new];
	prefsVC.modalPresentationStyle = UIModalPresentationFullScreen;
	[self presentViewController:prefsVC animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewAutomaticDimension;
}

@end

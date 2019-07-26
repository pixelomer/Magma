#import "HomeViewController.h"
#import "FeaturedSourceCell.h"

@implementation HomeViewController

static NSArray<NSArray *> *featuredSources; //Example: ( ("Section name", ( {...source A...}, {...source B...}, ... ), ... )

+ (void)load {
	featuredSources = @[
		@[@"Get Started", @[
			@{
				@"title" : @"Ubuntu Main Repository",
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
				@"description" : @"This is the default repository for the Ubuntu operating system.",
				@"image" : @"Ubuntu",
				@"url" : @"http://archive.ubuntu.com/ubuntu"
			},
			@{
				@"title" : @"Debian Main Repository",
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
				@"image" : @"Ubuntu",
				@"url" : @"https://deb.debian.org/debian"
			}
		]],
	];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
	self.title = @"Featured";
}

- (__kindof UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	FeaturedSourceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[FeaturedSourceCell alloc] initWithReuseIdentifier:@"cell"];
	cell.informationDictionary = [(NSArray *)featuredSources[indexPath.section][1] objectAtIndex:indexPath.row];
	return cell;
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
	// Show settings
}

@end

//
//  ViewController.m
//  KittenDemo
//
//  Created by Mario Diana on 7/31/24.
//

#import "ViewController.h"

#import "KittenViewModel.h"
#import "KittenStoring.h"

@interface ViewController ()
@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (nonatomic, strong) KittenViewModel* viewModel;
@property (nonatomic, strong) id<KittenStoring> store;
@end

@implementation ViewController

- (void)dealloc 
{
    [[self viewModel] removeObserver:self forKeyPath:@"image"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.store = CreateKittenStore();
    self.viewModel = [[KittenViewModel alloc] init];
    
    [[self viewModel] addObserver:self
                       forKeyPath:@"image"
                          options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                          context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKittenStoreFetchError:)
                                                 name:KittenStoreFetchErrorNotification
                                               object:nil];
}


- (void)handleKittenStoreFetchError:(NSNotification *)note
{
    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Error"
                                            message:[[note userInfo] objectForKey:@"error"]
                                     preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okay = [UIAlertAction actionWithTitle:@"Okay" 
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction* action) {
        [self updateUIEnabled:YES];
    }];
    
    [alert addAction:okay];
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)updateUIEnabled:(BOOL)enabled
{
    if (enabled) {
        [[self activityIndicator] setHidden:YES];
        [[self imageView] setAlpha:1.0];
    }
    else {
        [[self activityIndicator] setHidden:NO];
        [[self activityIndicator] startAnimating];
        [[self imageView] setAlpha:0.3];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    // Observe the view-model's image property and update the UI accordingly.
    if ([object isEqual:[self viewModel]] && [keyPath isEqualToString:@"image"]) {
        [self updateUIEnabled:YES];
        UIImage* image = [change valueForKey:NSKeyValueChangeNewKey];
        NSLog(@"## image: %@", image);
        [[self imageView] setImage:image];
    }
}


- (IBAction)fetchKitten:(id)sender
{
    if (![[self activityIndicator] isHidden]) {
        NSLog(@"## Request in progress.");
        return;
    }
    
    [self updateUIEnabled:NO];
    [[self store] fetchImageForKitten:[self viewModel]];
}

@end

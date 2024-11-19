//
//  ViewController.m
//  KittenDemo
//
//  Created by Mario Diana on 7/31/24.
//

#import "ViewController.h"
#import "KittenStoring.h"

@interface ViewController () <KittenUpdating>
@property (nonatomic, weak) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomButtonConstraint;
@property (nonatomic, strong) id<KittenStoring> store;
@property (nonatomic, assign, getter=hasDeviceNotch) BOOL deviceNotch;
@end

@implementation ViewController

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    self.store = CreateKittenStore();
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKittenStoreFetchError:)
                                                 name:KittenStoreFetchErrorNotification
                                               object:nil];
}


- (void)viewWillLayoutSubviews
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIWindow* window = [self keyWindow];
        
        if (window) {
            CGFloat padding = [window safeAreaInsets].bottom;
            self.bottomButtonConstraint.constant = (padding > 0.0) ? 0.0 : 20.0;
        }
    });
}


- (UIWindow *)keyWindow
{
    UIWindow* keyWindow = nil;

    for (id aScene in [[UIApplication sharedApplication] connectedScenes]) {
        UIWindow* window = [[aScene delegate] window];
        
        if ([window isKeyWindow]) {
            keyWindow = window;
            break;
        }
    }
    
    return keyWindow;
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


- (void)updateKitten:(UIImage *)image
{
    [self updateUIEnabled:YES];
    NSLog(@"## image: %@", image);
    [[self imageView] setImage:image];
}


- (IBAction)fetchKitten:(id)sender
{
    if (![[self activityIndicator] isHidden]) {
        NSLog(@"## Request in progress.");
        return;
    }
    
    [self updateUIEnabled:NO];
    [[self store] fetchImageWithUpdater:self];
}

@end

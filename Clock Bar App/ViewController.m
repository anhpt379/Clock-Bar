#import "ViewController.h"
#import "AppDelegate.h"
#import "AppConstants.h"
@import ServiceManagement;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activate:)
                                                 name:kEventShowPreferences
                                               object:nil];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [[self.view window] setTitle:@"Clock Bar"];
    [[self.view window] center];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    [[self.view window] setTitle:@"Clock Bar"];
}

- (IBAction)activate:(id)sender {
    [[self.view window] makeKeyAndOrderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)quitPressed:(id)sender {
    [NSApp terminate:nil];
}

@end

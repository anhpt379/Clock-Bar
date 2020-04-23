#import "ViewController.h"
#import "AppDelegate.h"
@import ServiceManagement;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"auto_login"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"auto_login"];
    }
        
    const BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:@"auto_login"];
    [self.autoLoginState setState: !state];
    
    BOOL hideStatusBarState = [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_status_bar"];
    [self.showInMenuBarState setState:hideStatusBarState];
    
    BOOL showSecondHandState = [[NSUserDefaults standardUserDefaults] boolForKey:@"show_second_hand"];
    [self.showSecondHandState setState:showSecondHandState];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    [[self.view window] setTitle:@"Clock Bar"];
    [[self.view window] center];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    [[[[NSApplication sharedApplication] windows] lastObject] setTitle:@"Clock Bar"];
}

- (IBAction)quitPressed:(id)sender {
    [NSApp terminate:nil]; //TODO or quit about window
}

- (IBAction)onLoginStartChanged:(id)sender {
    bool enableState = [self.autoLoginState state] == NSOnState;
    
    if (SMLoginItemSetEnabled((__bridge CFStringRef)@"info.averello.Clock-Launcher", (Boolean)enableState)) {
        [[NSUserDefaults standardUserDefaults] setBool:!enableState forKey:@"auto_login"];
    }
}

- (IBAction)showMenuBarChanged:(id)sender {
    bool enableState = [self.showInMenuBarState state] == NSOnState;
    [[NSUserDefaults standardUserDefaults] setBool:enableState forKey:@"hide_status_bar"];
    AppDelegate *appDelegate = (AppDelegate *) [[NSApplication sharedApplication] delegate];
    [appDelegate hideMenuBar:enableState];

    if (enableState == YES) {
        NSAlert* msgBox = [[NSAlert alloc] init] ;
        [msgBox setMessageText:@"Long press on the Touch Bar Clock Button to show Preferences when the Menu Item is disabled."];
        [msgBox addButtonWithTitle: @"OK"];
        [msgBox runModal];
    }
}

- (IBAction)showSecondHandChanged:(id)sender {
    BOOL enableState = [self.showSecondHandState state] == NSOnState;
    [[NSUserDefaults standardUserDefaults] setBool:enableState forKey:@"show_second_hand"];
    AppDelegate *appDelegate = (AppDelegate *) [[NSApplication sharedApplication] delegate];
    appDelegate.showSecondHand = enableState;
}

@end

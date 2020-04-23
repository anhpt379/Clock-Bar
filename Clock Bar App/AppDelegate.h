@import Cocoa;

#include "ClockView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;

@property (nonatomic, weak) IBOutlet NSTouchBar *touchBar;

@property (nonatomic, strong) NSStatusItem *statusBar;

@property (nonatomic, strong) ClockView *clockIcon;

@property (nonatomic, weak) IBOutlet ClockView *clockView;

@property (nonatomic, weak) IBOutlet NSButton *dateButton;

@property (nonatomic, weak) IBOutlet NSButton *timeButton;

- (IBAction)prefsMenuItemAction:(id)sender;

- (IBAction)quitMenuItemAction:(id)sender;

- (IBAction)presentTouchBar:(id)sender;

- (IBAction)copyDate:(id)sender;

- (IBAction)copyTime:(id)sender;

- (bool)showSecondHand;

- (void)setShowSecondHand:(bool)state;

- (void) hideMenuBar:(BOOL)enableState;

@end


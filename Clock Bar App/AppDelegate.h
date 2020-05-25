@import Cocoa;

#include "ClockView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSScrubberDataSource, NSScrubberDelegate>

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;

@property (nonatomic, weak) IBOutlet NSTouchBar *touchBar;

@property (nonatomic, strong) NSStatusItem *statusBar;

@property (nonatomic, strong) ClockView *clockIcon;

//@property (nonatomic, weak) IBOutlet ClockView *clockView;

@property (nonatomic, weak) IBOutlet NSButton *dateButton;

@property (nonatomic, weak) IBOutlet NSButton *timeButton;

@property (nonatomic, weak) IBOutlet NSScrubber *eventScrubber;

- (IBAction)prefsMenuItemAction:(id)sender;

- (IBAction)quitMenuItemAction:(id)sender;

- (IBAction)presentTouchBar:(id)sender;

- (IBAction)copyDate:(id)sender;

- (IBAction)copyTime:(id)sender;

@end


@import Cocoa;
@import ServiceManagement;
@import EventKit;
#import "AppDelegate.h"
#import "TouchBar.h"
#import "TouchDelegate.h"
#import "ClockView.h"

static const NSTouchBarItemIdentifier kClockIdentifier = @"ns.clock";

@interface AppDelegate () <TouchDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;

@property (nonatomic, strong) dispatch_block_t update;

@end

@implementation AppDelegate

@synthesize statusBar;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[[NSApplication sharedApplication] windows] lastObject] close];
    
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterFullStyle;
    _dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    _timeFormatter.timeStyle = NSDateFormatterShortStyle;
    _timeFormatter.dateFormat = @"HH:mm:ss";
    
    NSClickGestureRecognizer *const press =
    [[NSClickGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(onPressed:)];
    press.buttonMask = 0x1;
    press.allowedTouchTypes = NSTouchTypeMaskDirect;
    press.numberOfTouchesRequired = 1;
    
    NSPressGestureRecognizer *const longPress =
    [[NSPressGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(onLongPressed:)];
    longPress.buttonMask = 0x1;
    longPress.allowedTouchTypes = NSTouchTypeMaskDirect;
    longPress.minimumPressDuration = 0.5;
    longPress.numberOfTouchesRequired = 1;
    
    _clockIcon = [[ClockView alloc] initWithFrame:NSZeroRect];
    _clockIcon.date = [NSDate date];
    _clockIcon.color = [NSColor whiteColor];
    _clockIcon.showSecondHand = [[NSUserDefaults standardUserDefaults] boolForKey:@"show_second_hand"];
    [_clockIcon addGestureRecognizer:press];
    [_clockIcon addGestureRecognizer:longPress];
    
    NSCustomTouchBarItem *time = [[NSCustomTouchBarItem alloc] initWithIdentifier:kClockIdentifier];
    time.view = _clockIcon;

    [NSTouchBarItem addSystemTrayItem:time];
    DFRElementSetControlStripPresenceForIdentifier(kClockIdentifier, YES);
    
//    EKEventStore *store = [[EKEventStore alloc] initWithAccessToEntityTypes:EKEntityMaskEvent];
//    https://developer.apple.com/documentation/eventkit/ekeventstore/1507547-requestaccesstoentitytype?language=objc
    
    [self enableLoginAutostart];
    
    [self updateTime];
}

- (void)awakeFromNib {
    bool hideStatusBar = [[NSUserDefaults standardUserDefaults] objectForKey:@"hide_status_bar"] != nil
        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_status_bar"]
        : NO;

    [self hideMenuBar:hideStatusBar];
    
    [super awakeFromNib];
}

- (void)setupStatusBarItem {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusBar.menu = self.statusMenu;
    
    NSImage *statusImage = [self statusBarImage];
    
    statusImage.size = NSMakeSize(18, 18);
    statusImage.template = YES;
    
    self.statusBar.image = statusImage;
    self.statusBar.highlightMode = YES;
    self.statusBar.enabled = YES;
}


- (void)hideMenuBar:(BOOL)enableState {
    if (!enableState) {
        [self setupStatusBarItem];
    } else {
        self.statusBar = nil;
    }
}

- (bool)showSecondHand {
    return _clockIcon.showSecondHand;
}

- (void)setShowSecondHand:(bool)showSecondHand {
    _clockIcon.showSecondHand = showSecondHand;
    
    // Reschedule updateTime to take the new frequency into account
    [self updateTime];
}

- (void)updateTime {
    if (_update != nil) {
        dispatch_block_cancel(_update);
    }
    
    // Do the update
    NSDate *const now = [NSDate date];
    _clockIcon.date = now;
    
    // Also update the touch bar buttons if they're visible
    if (self.touchBar.isVisible) {
        self.clockView.date = now;
        self.dateButton.title = [_dateFormatter stringFromDate:now];
        self.timeButton.title = [_timeFormatter stringFromDate:now];
    }
    
    bool updateEverySecond = self.showSecondHand || self.touchBar.isVisible;
    
    // schedule efficient update
    NSCalendar *const calendar = [NSCalendar currentCalendar];
    NSDateComponents *const dateComponents = [calendar components:NSCalendarUnitNanosecond
                                                         fromDate:now];
    const NSInteger delay = (long) (updateEverySecond ? NSEC_PER_SEC : 60 * NSEC_PER_SEC) - dateComponents.nanosecond;
    
    __weak AppDelegate *welf = self;
    _update = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        __strong AppDelegate *strelf = welf;
        if (strelf == nil) { return; }
        [strelf updateTime];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) delay),
                   dispatch_get_main_queue(),
                   _update);
}

- (NSImage *)statusBarImage {
    return [NSImage imageNamed:@"clock-64"];
}

- (void)enableLoginAutostart {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"auto_login"] == nil) {
        return;
    }
    
    const BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:@"auto_login"];
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)@"info.averello.Clock-Launcher", !state)) {
        NSLog(@"The login was not succesfull");
    }
}

- (void)presentTouchBar:(id)sender {
    if (@available(macOS 10.14, *)) {
        [NSTouchBar presentSystemModalTouchBar:self.touchBar systemTrayItemIdentifier:kClockIdentifier];
    } else {
        [NSTouchBar presentSystemModalFunctionBar:self.touchBar systemTrayItemIdentifier:kClockIdentifier];
    }
    [self updateTime];
}

- (void)onPressed:(NSButton *)sender {
    [self presentTouchBar:nil];
}

- (void)onLongPressed:(NSPressGestureRecognizer *)recognizer {
    if (recognizer.state != NSGestureRecognizerStateBegan)
        return;
    [self prefsMenuItemAction:nil];
}

- (IBAction)prefsMenuItemAction:(id)sender {
    [[[[NSApplication sharedApplication] windows] lastObject] makeKeyAndOrderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)quitMenuItemAction:(id)sender {
    [NSApp terminate:nil];
}

void copyDateToPasteboard(NSDateFormatter *formatter) {
    NSPasteboard *board = [NSPasteboard generalPasteboard];
    [board declareTypes:@[NSPasteboardTypeString] owner:nil];
    [board setString:[formatter stringFromDate:[NSDate date]] forType:NSPasteboardTypeString];
}

- (IBAction)copyDate:(id)sender {
    copyDateToPasteboard(_dateFormatter);
}

- (IBAction)copyTime:(id)sender {
    copyDateToPasteboard(_timeFormatter);
}

@end

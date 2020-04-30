@import Cocoa;
@import ServiceManagement;
@import EventKit;
#import "AppDelegate.h"
#import "TouchBar.h"
#import "TouchDelegate.h"
#import "ClockView.h"

// So we don't need to import Carbon
#define kASAppleScriptSuite 'ascr'
#define kASSubroutineEvent  'psbr'
#define keyASSubroutineName 'snam'
//@import Carbon

static const NSTouchBarItemIdentifier kClockIdentifier = @"ns.clock";

static const NSTouchBarItemIdentifier kEventIdentifier = @"ns.clock.event";

@interface AppDelegate () <TouchDelegate, NSScrubberDataSource, NSScrubberDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, strong) NSArray *events;

@property (nonatomic, strong) dispatch_block_t update;

- (void) updateCalendarItems;

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
    _timeFormatter.dateFormat = @"HH:mm";
    
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

//    https://developer.apple.com/documentation/eventkit/ekeventstore/1507547-requestaccesstoentitytype?language=objc
    
    [self enableLoginAutostart];
    
    [self updateTime];
}

- (void)awakeFromNib {
    bool hideStatusBar = [[NSUserDefaults standardUserDefaults] objectForKey:@"hide_status_bar"] != nil
        ? [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_status_bar"]
        : NO;

    [self hideMenuBar:hideStatusBar];
    
    [_eventScrubber registerClass:[NSScrubberTextItemView class] forItemIdentifier:kEventIdentifier];
    
    [super awakeFromNib];
    
    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]) {
        case EKAuthorizationStatusAuthorized:
            NSLog(@"We're good");
            _eventStore = [[EKEventStore alloc] init];
            [self updateCalendarItems];
            break;
            
        case EKAuthorizationStatusDenied:
            NSLog(@"Denied");
            break;
        
        case EKAuthorizationStatusRestricted:
            NSLog(@"Restricted whatever that means");
            break;
            
        case EKAuthorizationStatusNotDetermined:
            NSLog(@"Undetermined");
            _eventStore = [EKEventStore alloc];
            [_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError * _Nullable error) {
                NSLog(@"Granted? %d or %@", granted, error);
                if (granted) {
                    self.eventStore = [self.eventStore init];
                    [self updateCalendarItems];
                }
            }];
            
            break;
    }
}

- (void)updateCalendarItems {
    [_eventStore reset];
    NSArray *calendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
    NSLog(@"Calendars %@", calendars);
    
    NSDate *now = [NSDate date];
    NSDate *future = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:7 toDate:now options:0];
    
    NSPredicate *pred = [_eventStore predicateForEventsWithStartDate:now endDate:future calendars:calendars];
    _events = [_eventStore eventsMatchingPredicate:pred];
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

- (NSInteger)numberOfItemsForScrubber:(nonnull NSScrubber *)scrubber {
    return _events == nil ? 0 : (NSInteger) [_events count];
}

- (__kindof NSScrubberItemView *)makeItemWithIdentifier:(NSUserInterfaceItemIdentifier)itemIdentifier owner:(id)owner {
    return [[NSScrubberTextItemView alloc] init];
}

- (nonnull __kindof NSScrubberItemView *)scrubber:(nonnull NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index {
    NSScrubberTextItemView *itemView = [scrubber makeItemWithIdentifier:kEventIdentifier owner:self];
    
    if (_events != nil && index < (NSInteger)[_events count]) {
        itemView.title = [(EKEvent*) [_events objectAtIndex:(NSUInteger)index] title];
    }
    return itemView;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index {
    NSLog(@"Selected item %ld", index);
    
    EKEvent *event = (EKEvent*) [_events objectAtIndex:(NSUInteger)index];
    NSLog(@"%ld", [event.startDate timeIntervalSinceReferenceDate]);
    [self openEventInCalendar:event];
}

- (void)openEventInCalendar:(EKEvent*)event {
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle] pathForResource:@"calendar" ofType:@"js"]];
    NSDictionary* error = nil;
    NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:url error:&error];
    if (error != nil) {
        NSLog(@"Could not instantiate applescript %@", error);
        return;
    }
    
    //Get a descriptor for ourself
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSAppleEventDescriptor *thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
    
    //We need these constants from the Carbon OpenScripting framework, but we don't actually need Carbon.framework...
    NSAppleEventDescriptor *containerEvent = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:thisApplication returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    
    //Set the target function
    [containerEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:@"showEventOrDate"] forKeyword:keyASSubroutineName];
    
    // Build argument list
    NSAppleEventDescriptor *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
        
    // First argument: event identifier
    [arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:event.eventIdentifier] atIndex:1];
    
    // Second argument: event date (in case of recurring events: which one?)
    NSDateFormatter *rfc2822Formatter = [[NSDateFormatter alloc] init];
    rfc2822Formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    [arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[rfc2822Formatter stringFromDate:event.startDate]] atIndex:2];
    
    // Push arguments and execute!
    [containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
    [script executeAppleEvent:containerEvent error:&error];
    if (error != nil) {
        NSLog(@"error while executing script. Error %@", error);
    }
}

@end

@import Cocoa;
@import ServiceManagement;
@import EventKit;
#import "AppConstants.h"
#import "AppDelegate.h"
#import "TouchBar.h"
#import "TouchDelegate.h"
#import "ClockView.h"
#import "ScrubberEventItemView.h"

#define LE_CHR(a,b,c,d) ( ((a)<<24) | ((b)<<16) | ((c)<<8) | (d) )

// So we don't need to import Carbon
#define kASAppleScriptSuite LE_CHR('a','s','c','r')
#define kASSubroutineEvent  LE_CHR('p','s','b','r')
#define keyASSubroutineName LE_CHR('s','n','a','m')

@interface AppDelegate () <TouchDelegate, NSScrubberDataSource, NSScrubberDelegate>

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, strong) NSArray *events;

@property (nonatomic, strong) NSArray *currentEvents;

@property (nonatomic, strong) dispatch_block_t update;

@property BOOL showEventsOnClockFace;

- (void)setupTouchBarItem;
- (void)loadPreferences;
- (void)updateLaunchOnLogin;
- (void)updateShowMenuBarItem;
- (void)updateClockView;

- (void)requestUpdateOfCalendarItems;
- (void)setupCalendarItems;
- (void)updateCalendarItems;
- (void)openEventInCalendar:(EKEvent*)event;

@end

@interface NSDate (DayAdditions)

- (NSDate*) startOfDay;
- (NSDate*) endOfDay;

@end

@implementation AppDelegate

@synthesize statusBar;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[[NSApplication sharedApplication] windows] lastObject] close];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateStyle = NSDateFormatterFullStyle;
    _dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    _timeFormatter = [[NSDateFormatter alloc] init];
    _timeFormatter.timeStyle = NSDateFormatterShortStyle;
    _timeFormatter.dateFormat = @"HH:mm";
    
    NSDictionary *defaults = @{
        kPrefLaunchOnLogin: @false,
        kPrefShowMenuBarItem: @true,
        kPrefShowSecondHand: @false,
        kPrefShowEventsOnClockFace: @false
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadPreferences)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    [self setupTouchBarItem];
    [self loadPreferences];
    [self updateTime];
}

- (void) setupTouchBarItem {
    NSClickGestureRecognizer *const press = [[NSClickGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(onPressed:)];
    press.buttonMask = 0x1;
    press.allowedTouchTypes = NSTouchTypeMaskDirect;
    press.numberOfTouchesRequired = 1;
    
    NSPressGestureRecognizer *const longPress = [[NSPressGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(onLongPressed:)];
    longPress.buttonMask = 0x1;
    longPress.allowedTouchTypes = NSTouchTypeMaskDirect;
    longPress.minimumPressDuration = 0.5;
    longPress.numberOfTouchesRequired = 1;
    
    _clockIcon = [[ClockView alloc] initWithFrame:NSZeroRect];
    _clockIcon.date = [NSDate date];
    _clockIcon.color = [NSColor whiteColor];
    _clockIcon.showSecondHand = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefShowSecondHand];
    [_clockIcon addGestureRecognizer:press];
    [_clockIcon addGestureRecognizer:longPress];
    
    NSCustomTouchBarItem *time = [[NSCustomTouchBarItem alloc] initWithIdentifier:kClockIdentifier];
    time.view = _clockIcon;

    [NSTouchBarItem addSystemTrayItem:time];
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);
    DFRElementSetControlStripPresenceForIdentifier(kClockIdentifier, YES);
}

- (void) loadPreferences {
    [self updateLaunchOnLogin];
    [self updateShowMenuBarItem];
    [self updateClockView];
}

- (void)awakeFromNib {
    [_eventScrubber registerClass:[ScrubberEventItemView class] forItemIdentifier:kEventIdentifier];
    
    [self requestUpdateOfCalendarItems];
    
    [super awakeFromNib];
}

- (void)requestUpdateOfCalendarItems {
    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]) {
        case EKAuthorizationStatusAuthorized:
            NSLog(@"We're good");
            _eventStore = [[EKEventStore alloc] init];
            [self setupCalendarItems];
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
                    [self setupCalendarItems];
                }
            }];
            break;
    }
}

- (void)setupCalendarItems {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCalendarItems)
                                                 name:EKEventStoreChangedNotification
                                               object:_eventStore];
    [self updateCalendarItems];
}

- (void)updateCalendarItems {
    [_eventStore reset];
    NSArray *calendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
    
    calendars = [calendars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(EKCalendar *calendar, NSDictionary<NSString *,id> *bindings) {
        return true; // TODO only show selected calendars
    }]];
    
    // Give me all events of today
    NSDate *now = [NSDate date];
    NSDate *halfDay = [now dateByAddingTimeInterval:12*60*60];
    NSPredicate *pred = [_eventStore predicateForEventsWithStartDate:now endDate:halfDay calendars:calendars];
    NSArray *events = [_eventStore eventsMatchingPredicate:pred];
    
    // Remove all-day events
    events = [events filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(EKEvent *event, id _) {
        return !event.allDay;
    }]];
    
    // Sort by start date
    events = [events sortedArrayUsingComparator:^NSComparisonResult(EKEvent *lft, EKEvent *rht) {
        return [lft.startDate isGreaterThan:rht.startDate];
    }];
    
    _events = events;
    
    [self.eventScrubber reloadData];
}

- (void)updateShowMenuBarItem {
    const BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefShowMenuBarItem];
    
    if (enabled && self.statusBar)
        return;
    
    if (!enabled) {
        self.statusBar = nil;
        return;
    }
    
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusBar.menu = self.statusMenu;

    NSImage *statusImage = [NSImage imageNamed:NSImageNameApplicationIcon];
    statusImage.size = NSMakeSize(18, 18);
    statusImage.template = YES;

    self.statusBar.button.image = statusImage;
    self.statusBar.highlightMode = YES;
    self.statusBar.button.enabled = YES;
}

- (void)updateLaunchOnLogin {
    const BOOL state = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefLaunchOnLogin];
    if (!SMLoginItemSetEnabled((__bridge CFStringRef)@"com.github.jelmervdl.Clock-Bar-Launcher", state ? TRUE : FALSE)) {
        NSLog(@"Could not (de)register the login item");
    }
}

- (void)updateClockView {
    _clockIcon.showSecondHand = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefShowSecondHand];
    _clockIcon.showEventBackground = true;
    _clockIcon.showEventOutline = false;
    
    _showEventsOnClockFace = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefShowEventsOnClockFace];
    
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
    _clockIcon.events = _showEventsOnClockFace ? _events : nil;
    
    // Also update the touch bar buttons if they're visible
    if (self.touchBar.isVisible) {
        self.clockView.date = now;
        self.dateButton.title = [_dateFormatter stringFromDate:now];
        self.timeButton.title = [_timeFormatter stringFromDate:now];
    }
    
    BOOL updateEverySecond = self.clockView.showSecondHand || self.touchBar.isVisible;
    
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

- (void)presentTouchBar:(id)sender {
    [NSTouchBar presentSystemModalTouchBar:self.touchBar systemTrayItemIdentifier:kClockIdentifier];
    
    [self updateTime];
}

- (void)onPressed:(NSButton *)sender {
    [self requestUpdateOfCalendarItems];
    [self presentTouchBar:nil];
}

- (void)onLongPressed:(NSPressGestureRecognizer *)recognizer {
    if (recognizer.state != NSGestureRecognizerStateBegan)
        return;
    [self prefsMenuItemAction:nil];
}

- (IBAction)prefsMenuItemAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kEventShowPreferences object:sender];
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
    ScrubberEventItemView *itemView = [scrubber makeItemWithIdentifier:kEventIdentifier owner:self];
    
    if (_events != nil && index < (NSInteger)[_events count]) {
        itemView.event = (EKEvent*) [_events objectAtIndex:(NSUInteger)index];
    }
    return itemView;
}

- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index {
    EKEvent *event = (EKEvent*) [_events objectAtIndex:(NSUInteger)index];
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

@implementation NSDate (DayAdditions)

-(NSDate *)startOfDay {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:self];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    return [cal dateFromComponents:components];
}

-(NSDate *)endOfDay {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ) fromDate:self];
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    return [cal dateFromComponents:components];
}

@end

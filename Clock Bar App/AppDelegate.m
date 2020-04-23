@import Cocoa;
@import ServiceManagement;
#import "AppDelegate.h"
#import "TouchBar.h"
#import "TouchDelegate.h"

static const NSTouchBarItemIdentifier kMuteIdentifier = @"ns.clock";

@interface AppDelegate () <TouchDelegate>

@property (nonatomic, strong) NSTextField *label;

@property (nonatomic, strong) NSDateFormatter *timeformatter;
@property (nonatomic, strong) NSString *format;

@property (nonatomic, strong) dispatch_block_t update;

@end

@implementation AppDelegate

@synthesize statusBar;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[[NSApplication sharedApplication] windows] lastObject] close];
    
    DFRSystemModalShowsCloseBoxWhenFrontMost(YES);
    
    _timeformatter = [[NSDateFormatter alloc] init];
    _timeformatter.timeStyle = NSDateFormatterShortStyle;
    _timeformatter.dateFormat = _format;
    
    NSDate *const now = [NSDate date];
    NSString *const newDateString = [_timeformatter stringFromDate:now];
    
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
    
    NSFont *systemFont = [NSFont systemFontOfSize:14.0f];
    NSDictionary * fontAttributes =
    [[NSDictionary alloc] initWithObjectsAndKeys:systemFont, NSFontAttributeName, nil];
    
    NSMutableAttributedString *attributedTitle =
    [[NSMutableAttributedString alloc] initWithString:newDateString
                                           attributes:fontAttributes];
    
    NSString *const colorString = [[NSUserDefaults standardUserDefaults] objectForKey:@"clock_color"];
    NSColor *color = nil;
    if (colorString == nil){
        color = [NSColor whiteColor];
    }
    else {
        color = [self colorForString:colorString];
    }
    
    [attributedTitle addAttribute:NSForegroundColorAttributeName
                            value:color
                            range:NSMakeRange(0, newDateString.length)];
    _label = [NSTextField labelWithAttributedString:attributedTitle];
    _label.bezeled = NO;
    _label.drawsBackground = NO;
    _label.editable = NO;
    _label.selectable = NO;
    _label.enabled = YES;
    _label.allowsEditingTextAttributes = NO;
    _label.allowsExpansionToolTips = NO;
    _label.allowsCharacterPickerTouchBarItem = NO;
    _label.allowsDefaultTighteningForTruncation = NO;
    _label.maximumNumberOfLines = 1;
    _label.usesSingleLineMode = YES;
    
    _label.allowedTouchTypes = NSTouchTypeMaskDirect;
    _label.alignment = NSTextAlignmentCenter;
    
    _label.backgroundColor = NSColor.clearColor;
    [_label addGestureRecognizer:press];
    [_label addGestureRecognizer:longPress];
    
    
    NSCustomTouchBarItem *time = [[NSCustomTouchBarItem alloc] initWithIdentifier:kMuteIdentifier];
    NSView *const container = [[NSView alloc] initWithFrame:NSZeroRect];
    [container addSubview:_label];
    [_label sizeToFit];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
    [_label.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
    [_label.centerYAnchor constraintEqualToAnchor:container.centerYAnchor]]];
    time.view = container;
    
    
    [NSTouchBarItem addSystemTrayItem:time];
    DFRElementSetControlStripPresenceForIdentifier(kMuteIdentifier, YES);
    
    [self enableLoginAutostart];
    
    [self updateTime];
}

- (void)awakeFromNib {
    
    _format = @"HH:mm";
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"clock_format"] != nil) {
        _format = [[NSUserDefaults standardUserDefaults] stringForKey:@"clock_format"];
    }
    
    BOOL hideStatusBar = NO;
    BOOL statusBarButtonToggle = NO;
    BOOL useAlternateStatusBarIcons = NO;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"hide_status_bar"] != nil) {
        hideStatusBar = [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_status_bar"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"status_bar_button_toggle"] != nil) {
        statusBarButtonToggle = [[NSUserDefaults standardUserDefaults] boolForKey:@"status_bar_button_toggle"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"status_bar_alternate_icons"] != nil) {
        useAlternateStatusBarIcons = [[NSUserDefaults standardUserDefaults] boolForKey:@"status_bar_alternate_icons"];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:hideStatusBar forKey:@"hide_status_bar"];
    [[NSUserDefaults standardUserDefaults] setBool:statusBarButtonToggle forKey:@"status_bar_button_toggle"];
    [[NSUserDefaults standardUserDefaults] setBool:useAlternateStatusBarIcons forKey:@"status_bar_alternate_icons"];
    
    if (!hideStatusBar) {
        [self setupStatusBarItem];
    }
    
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
    }
    else {
        self.statusBar = nil;
    }
}


- (void)changeColor:(NSColor *)color {
    NSMutableAttributedString *const title = _label.attributedStringValue.mutableCopy;
    [title addAttribute:NSForegroundColorAttributeName
                  value:color
                  range:NSMakeRange(0, title.length)];
    _label.attributedStringValue = title;
}

- (void)updateTime {
    if (_update != nil) {
        dispatch_block_cancel(_update);
    }
    NSDate *const now = [NSDate date];
    NSString *const time = [_timeformatter stringFromDate:now];
    NSMutableAttributedString *const title = _label.attributedStringValue.mutableCopy;
    title.mutableString.string = time;
    _label.attributedStringValue = title;
    
    // schedule efficient update
    NSCalendar *const calendar = [NSCalendar currentCalendar];
    NSDateComponents *const dateComponents = [calendar components:NSCalendarUnitMinute
                                                         fromDate:now];
    const NSTimeInterval delay = 60 - dateComponents.minute;
    __weak AppDelegate *welf = self;
    _update = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        __strong AppDelegate *strelf = welf;
        if (strelf == nil) { return; }
        [strelf updateTime];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   _update);
}


- (NSColor *)colorForString:(NSString *)sender{
    return [self colorWithHexColorString:sender];
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
//        NSLog(@"The login was not succesfull");
    }
}

- (void)onPressed:(NSButton *)sender {
    if ([_format isEqual:@"hh:mm"]){
        _format = @"HH:mm";
    } else {
        _format = @"hh:mm";
    }
    _timeformatter.dateFormat = _format;
    [self updateTime];
    [NSUserDefaults.standardUserDefaults setObject:_format
                                            forKey:@"clock_format"];
}

- (void)onLongPressed:(NSPressGestureRecognizer *)recognizer {
    if (recognizer.state != NSGestureRecognizerStateBegan) { return; }
    [[[[NSApplication sharedApplication] windows] lastObject] makeKeyAndOrderFront:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)prefsMenuItemAction:(id)sender {
    [self onLongPressed:sender];
}

- (IBAction)quitMenuItemAction:(id)sender {
    [NSApp terminate:nil];
}

- (NSColor*)colorWithHexColorString:(NSString*)inColorString {
    NSColor* result = nil;
    unsigned colorCode = 0;
    unsigned char redByte, greenByte, blueByte;
    
    if (nil != inColorString)
    {
        NSScanner* scanner = [NSScanner scannerWithString:inColorString];
        (void) [scanner scanHexInt:&colorCode]; // ignore error
    }
    redByte = (unsigned char)(colorCode >> 16);
    greenByte = (unsigned char)(colorCode >> 8);
    blueByte = (unsigned char)(colorCode); // masks off high bits
    
    result = [NSColor
              colorWithCalibratedRed:(CGFloat)redByte / 0xff
              green:(CGFloat)greenByte / 0xff
              blue:(CGFloat)blueByte / 0xff
              alpha:1.0];
    return result;
}

@end

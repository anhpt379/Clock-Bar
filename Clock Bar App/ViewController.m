#import "ViewController.h"
#import "AppDelegate.h"
#import "AppConstants.h"
@import ServiceManagement;
@import EventKit;

@interface NSImage (TintExtension)

- (NSImage *)tint:(NSColor*)color;

@end

@implementation ViewController

- (void)awakeFromNib {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activate:)
                                                 name:kEventShowPreferences
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initEventStore:)
                                                 name:kEventInitEventStore
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

- (void)initEventStore:(NSNotification *)notification {
    _eventStore = [notification.userInfo objectForKey:@"eventStore"];
    [self fetchCalendarsFromEventStore];
}

- (void)fetchCalendarsFromEventStore {
    if (_eventStore == nil)
        return;
    
    NSMutableArray *sources = [NSMutableArray array];
    
    for (EKSource *source in [_eventStore sources]) {
        NSArray *calendars = [[source calendarsForEntityType:EKEntityTypeEvent] allObjects];
        if ([calendars count] > 0) {
            [sources addObject:@{
                @"title": source.title,
                @"calendars": calendars
            }];
        }
    }
    
    _eventSources = sources;
    
    if (_calendarTable) {
        NSOutlineView *calendarTable = _calendarTable;
        [calendarTable reloadData];
        [calendarTable expandItem:nil expandChildren:YES];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return [_eventSources objectAtIndex:(NSUInteger)index];
    } else {
        return [[(NSDictionary*)item objectForKey:@"calendars"] objectAtIndex:(NSUInteger)index];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item {
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[NSDictionary class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (_eventSources == nil) {
        return 0;
    } else if (item == nil) {
        return (NSInteger)[_eventSources count];
    } else {
        return (NSInteger)[[(NSDictionary*)item objectForKey:@"calendars"] count];
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (item == nil)
        return nil;
    
    NSTableCellView *view;
    
    if ([item isKindOfClass:[NSDictionary class]]) {
        view = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        view.textField.stringValue = [(NSDictionary*)item objectForKey:@"title"];
    } else if ([item isKindOfClass:[EKCalendar class]]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray<NSString*> *enabledCalendars = [defaults stringArrayForKey:kPrefCalendars];
        
        view = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
        NSButton *checkbox = (NSButton*)[view.subviews objectAtIndex:0];
        checkbox.title = [(EKCalendar*) item title];
        checkbox.state = enabledCalendars == nil || [enabledCalendars containsObject:[(EKCalendar*) item calendarIdentifier]] ? NSControlStateValueOn : NSControlStateValueOff;
//        checkbox.image = [NSImage imageNamed:NSImageNameMobileMe];
//        checkbox.image = [checkbox.image tint:[(EKCalendar*)item color]];
    }
    
    return view;
}

- (IBAction)calendarToggled:(id)sender {
    NSInteger row = [self.calendarTable rowForView:sender];
    
    if (row < 0)
        return;
    
    id item = [self.calendarTable itemAtRow:row];
    if (![item isKindOfClass:[EKCalendar class]])
        return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray<NSString*> *enabledCalendars = [defaults stringArrayForKey:kPrefCalendars];
    
    if (enabledCalendars == nil) {
        enabledCalendars = @[];
        for (NSDictionary* source in _eventSources)
            for (EKCalendar* calendar in [source objectForKey:@"calendars"])
                enabledCalendars = [enabledCalendars arrayByAddingObject:calendar.calendarIdentifier];
    }
    
    if ([(NSButton*)sender state] == NSControlStateValueOn)
        enabledCalendars = [enabledCalendars arrayByAddingObject:[(EKCalendar*)item calendarIdentifier]];
    else
        enabledCalendars = [enabledCalendars filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* identifier, id _) {
            return ![identifier isEqualToString:[(EKCalendar*)item calendarIdentifier]];
        }]];
    
    [defaults setObject:enabledCalendars forKey:kPrefCalendars];
}

@end

@implementation NSImage (TintExtension)

- (NSImage *)tint:(NSColor*)color {
    NSImage *image = [self copy];
    [image lockFocus];
    [color set];
    NSRect rect = NSMakeRect(0, 0, image.size.width, image.size.height);
    NSRectFillUsingOperation(rect, NSCompositingOperationSourceAtop);
    [image unlockFocus];
    return image;
}

@end

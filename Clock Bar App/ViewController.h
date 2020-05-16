@import Cocoa;
@import EventKit;

@interface ViewController : NSViewController<NSOutlineViewDataSource,NSOutlineViewDelegate>

@property (nonatomic, weak) IBOutlet NSOutlineView *calendarTable;

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic, strong) NSArray *eventSources;

- (void)initEventStore:(NSNotification *)notification;

- (void)fetchCalendarsFromEventStore;

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item;

- (IBAction)calendarToggled:(id)sender;

@end

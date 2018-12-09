@import Cocoa;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusBar;

- (IBAction)prefsMenuItemAction:(id)sender;

- (IBAction)quitMenuItemAction:(id)sender;

@property (nonatomic, weak) IBOutlet NSMenuItem *muteMenuItem;

- (void) hideMenuBar:(BOOL)enableState;
- (void) changeColor:(id)sender;
- (NSColor*)colorWithHexColorString:(NSString*)inColorString;


@end


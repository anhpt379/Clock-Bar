#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (nonatomic, weak) IBOutlet NSButton *autoLoginState;
@property (nonatomic, weak) IBOutlet NSButton *showInMenuBarState;
@property (nonatomic, weak) IBOutlet NSButton *showSecondHandState;

- (IBAction)showMenuBarChanged:(id)sender;
- (IBAction)showSecondHandChanged:(id)sender;

@end


#import <Cocoa/Cocoa.h>
#import "WebViewController.h"
#import "TrayMenu.h"
#import "SPMediaKeyTap.h"

@interface YamAppDelegate : NSObject<NSApplicationDelegate>
{
    NSWindow* window;
	WebViewController* webViewController;
	TrayMenu* trayMenu;
@private
	NSString* defaultWindowTitle;
    SPMediaKeyTap* mediaKeyTap;
}

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet WebViewController* webViewController;
@property (assign) IBOutlet TrayMenu* trayMenu;
@end

#import <Cocoa/Cocoa.h>
#import "WebViewController.h"

@interface TrayMenu : NSObject {
	WebViewController* controller;
@private
	NSStatusItem* statusItem;
	NSMenu* menu;
	NSMenuItem* titleMenuItem;
}

@property(assign) IBOutlet WebViewController* controller;

- (void)initMenu;

@end

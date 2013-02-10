#import "YamAppDelegate.h"

@implementation YamAppDelegate

@synthesize window;
@synthesize webViewController;
@synthesize trayMenu;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
	[webViewController loadStartPage];
	[trayMenu initMenu];
	[webViewController addObserver:self
					   forKeyPath:@"trackName"
					   options:NSKeyValueObservingOptionNew
					   context:nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
        [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
        nil]];
    mediaKeyTap = [[SPMediaKeyTap alloc]initWithDelegate:self];
    if([SPMediaKeyTap usesGlobalMediaKeyTap])
		[mediaKeyTap startWatchingMediaKeys];
	else
		NSLog(@"Media key monitoring disabled");
	defaultWindowTitle = window.title;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	NSLog(@"will terminate");
	[webViewController saveState];
    [mediaKeyTap stopWatchingMediaKeys];
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
	if (object == webViewController && [@"trackName" isEqual:keyPath]) {
		NSString* newValue = [change objectForKey: NSKeyValueChangeNewKey];
		if (newValue && [newValue length] > 0) {
			window.title = newValue;
		}
		else {
			window.title = defaultWindowTitle;
		}
	}
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event
{
    if ([event type] != NSSystemDefined || [event subtype] != SPSystemDefinedEventMediaKeys)
        return;
    
	// here be dragons...
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	//int keyRepeat = (keyFlags & 0x1);
	
	if (keyIsPressed) {		
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
                [webViewController playAction:nil];
				break;
				
			case NX_KEYTYPE_FAST:
				[webViewController nextAction:nil];
                break;
				
			case NX_KEYTYPE_REWIND:
                [webViewController prevAction:nil];
				break;
                
			default:				
				break;                
		}
	}
}


-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}


@end

#import "TrayMenu.h"


@implementation TrayMenu

@synthesize controller;

- (void) actionQuit:(id)sender 
{
	[NSApp terminate:sender];
}

- (NSMenu *) createMenu 
{
	NSZone *menuZone = [NSMenu menuZone];
	menu = [[NSMenu allocWithZone:menuZone] init];
	NSMenuItem *menuItem;
	
	// Add To Items
	menuItem = [menu addItemWithTitle:@"Play/Pause"
							   action:@selector(playAction:)
						keyEquivalent:@""];
	[menuItem setTarget:controller];
	
	// Add Separator
	[menu addItem:[NSMenuItem separatorItem]];
	
	menuItem = [menu addItemWithTitle:@"Previous"
							   action:@selector(prevAction:)
						keyEquivalent:@""];
	[menuItem setTarget:controller];
	
	
	menuItem = [menu addItemWithTitle:@"Next"
							   action:@selector(nextAction:)
						keyEquivalent:@""];
	[menuItem setTarget:controller];
	
	// Add Separator
	[menu addItem:[NSMenuItem separatorItem]];
	
	// Add Quit Action
	menuItem = [menu addItemWithTitle:@"Quit"
							   action:@selector(actionQuit:)
						keyEquivalent:@""];
	[menuItem setToolTip:@"Click to Quit this App"];
	[menuItem setTarget:self];
	
	return menu;
}


- (void) actionStatusItemClick:(id)sender
{
	[self createMenu];
	
	// Add Separator
	[menu addItem:[NSMenuItem separatorItem]];
	
	NSArray* playlist = [controller fetchPlaylist];
	if (playlist) {
		for (PlaylistTrack* track in playlist) {
			NSMenuItem* item = [menu addItemWithTitle:track.title action:@selector(playPlaylistItem:) keyEquivalent:@""];
            [item setTarget:controller];
            [item setRepresentedObject:track];
            if (track.current)
                [item setState:NSOnState];
		}
	}
	
	[statusItem	popUpStatusItemMenu:menu];
}

- (void) initMenu 
{
	//[self createMenu];
	
	statusItem = [[[NSStatusBar systemStatusBar]
					statusItemWithLength:NSVariableStatusItemLength] retain];
	//[statusItem setMenu:menu];
	[statusItem setHighlightMode:YES];
	[statusItem setImage:[NSImage imageNamed:@"yamstatusicon2.png"]];
	[statusItem setTarget:self];
	[statusItem setAction:@selector(actionStatusItemClick:)];
	[controller addObserver:self
				forKeyPath:@"trackName"
				options:NSKeyValueObservingOptionNew
				context:nil];
}

-(void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id) object
                        change: (NSDictionary *) change context: (void *) context
{
	if (object == controller && [@"trackName" isEqual: keyPath]) {
		NSString* newValue = [change objectForKey: NSKeyValueChangeNewKey];
		if (newValue) {
			[statusItem	setToolTip:newValue];
		}
		else {
			[statusItem setToolTip:@"Player stopped"];
		}
	}
}

@end

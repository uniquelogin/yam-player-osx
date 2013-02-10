#import "WebViewController.h"
#import <Foundation/NSURLRequest.h>
#import <Foundation/NSURL.h>

@implementation PlaylistTrack

@synthesize index;
@synthesize title;
@synthesize tid;
@synthesize current;

- (PlaylistTrack*)init
{
	return self;
}


@end


@implementation WebViewController

@synthesize trackName;

- (void)loadStartPage 
{
	NSLog(@"Start page load requested");
	NSURLRequest* req = [NSURLRequest requestWithURL: [NSURL URLWithString:@"http://music.yandex.ru/"] 
										 cachePolicy: NSURLRequestReloadRevalidatingCacheData
									 timeoutInterval: 15];
	WebFrame* mainFrame = [webView mainFrame];
	[mainFrame loadRequest:req];
	NSLog(@"Loading start page");
	
	titleUpdateTimer = 
		[NSTimer scheduledTimerWithTimeInterval: 1
				 target: self
				 selector: @selector(updateTitle:)
				 userInfo: nil
				 repeats: YES];	
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	NSLog(@"Started provisional load for frame");
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSLog(@"Failed provisional load for frame: %@", error);
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
	NSLog(@"Committed load for frame");
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	NSLog(@"Failed load for frame: %@", error);
}

- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame
{
	NSLog(@"Server redirect received");
}

- (NSString*) getPlayerState:(WebScriptObject*)window
{
	NSObject* result = [window evaluateWebScript:@"Mu.Player.state"];
	if (!result || !([result isKindOfClass:[NSString class]])) {
		NSLog(@"Failed to get state");
		return nil;
	}
	return [result copy];
}

- (int)safeConvertInt: (NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSNumber class]])
		return [(NSNumber*)obj intValue];
	else
		return 0;
}

- (NSString *)safeConvertString: (NSObject*)obj
{
	NSLog(@"%@", obj);
	if (obj && [obj isKindOfClass:[NSString class]])
		return (NSString*) obj;
	else
		return nil;
}

- (BOOL)isUndefined: (NSObject*)obj
{
	return (!obj || [obj isKindOfClass:[WebUndefined class]]);
}

- (NSArray*) fetchPlaylist
{
	WebScriptObject* win = [[webView mainFrame] windowObject];
	if (!win) {
		return nil;
	}
	
	//[win evaluateWebScript:@"Mu.Songbird.refreshView(null, null)"];
	
	NSObject* webPlaylist = [win evaluateWebScript:@"Mu.Songbird.playingList"];
	if ([self isUndefined:webPlaylist]) {
        NSLog(@"No playlist...");
        if (webPlaylist)
            [webPlaylist release];
		return nil;
    }
    
    NSObject* currTrack = [win evaluateWebScript:@"Mu.Player.getCurrentTrack();"];
    if ([self isUndefined:currTrack]) {
        NSLog(@"No current track...");
        if (currTrack)
            [currTrack release];
        currTrack = nil;
    }
    
    NSString* currTrackId = @"";
    if (currTrack)
        currTrackId = [self safeConvertString:[currTrack valueForKey:@"id"]];
    NSLog(@"Current track ID: %@", currTrackId);
    
    NSArray* args = [NSArray array];
	int len = [self safeConvertInt:[webPlaylist callWebScriptMethod:@"getLength" withArguments:args]];
    [args release];
    
	NSMutableArray* fullResult = [NSMutableArray arrayWithCapacity:len];
	
	NSLog(@"%d tracks", len);
	int i;
    int currTrackIndex = -1;
	for (i = 0; i < len; ++i) {
        args = [NSArray arrayWithObjects:[NSNumber numberWithInt:i], nil];
		NSObject* rawTrackEntry = [webPlaylist callWebScriptMethod:@"trackEntryAt" withArguments:args];
		if ([self isUndefined:rawTrackEntry])
			break;
        [args release];
        
        args = [NSArray array];
        NSObject* rawTrack = [rawTrackEntry callWebScriptMethod:@"getTrack" withArguments:args];
        if ([self isUndefined:rawTrack])
            break;
        
        NSString* tid = [self safeConvertString:[rawTrackEntry valueForKey:@"id"]];
        if ([tid isEqualToString:currTrackId]) {
            currTrackIndex = i;
            int newLen = currTrackIndex + 5;
            len = newLen < len ? newLen : len;
        }
        NSLog(@"track id: %@, current track id: %@", tid, currTrackId);
        
		NSString* title = [self safeConvertString:[rawTrack valueForKey:@"title"]];
		PlaylistTrack* resultTrack = [[PlaylistTrack alloc] init];
		if (!title)
			title = @"--undefined--";
		resultTrack.title = title;
        resultTrack.index = i;
        resultTrack.current = (currTrackIndex == i);
		[fullResult addObject:resultTrack];
	}
    
    NSMutableArray* result = nil;
    if (currTrackIndex < 0) {
        result = fullResult;
    }
    else {
        result = [NSMutableArray arrayWithCapacity:30];
        int start = currTrackIndex - 5;
        if (start < 0)
            start = 0;
        for (int i = start; i < len; ++i) {
            [result addObject:[fullResult objectAtIndex:i]];
        }
    }
	return result;
}

- (void)updateTitle: (NSTimer *) timer
{
	WebScriptObject* win = [[webView mainFrame] windowObject];
	if (!win) {
		self.trackName = @"";
		return;
	}
	NSString* state = [self getPlayerState:win];
	if (!state) {
		self.trackName = @"";
		return;
	}

	if (!([@"playing" isEqualToString:state] || [@"paused" isEqualToString:state])) {
		self.trackName = @"";
		return;
	}
	
	NSObject* result = [win evaluateWebScript:@"(function(){var trk = Mu.Player.currentTrack.getTrack(); return trk.artist + ' - ' + trk.title;})();"];
	if (!result || !([result isKindOfClass:[NSString class]])) {
		self.trackName = @"";
		return;
	}
	
	self.trackName = (NSString*)([result copy]);
}

- (IBAction)playAction:id
{
	NSLog(@"Clicked Play");
	WebScriptObject* win = [[webView mainFrame] windowObject];
	if (!win) {
		NSLog(@"No window object");
		return;
	}
	NSString* state = [self getPlayerState:win];
	if (!state) {
		return;
	}
	
	NSString* command = nil;
	if ([state isEqualToString:@"paused"]) 
		command = @"Mu.Player.resume();";
	else if ([state isEqualToString:@"playing"])
		command = @"Mu.Player.pause();";
	else if ([state isEqualToString:@"waiting"])
		command = @"(function(evt, data) {"
        "var pls = (Mu.Songbird.playingList != null) ? Mu.Songbird.playingList : Mu.Songbird.main_playlist;" 
		"var track = (pls.getLength() > 0) ? pls.entries[0] : null;"
		"if (track) {"
		"Mu.Songbird.play(track);"
		"}"
		"})();";
	else {
		NSLog(@"Unknown player state: %@", state);
	}
	
	NSLog(@"Current player state: %@", state);
	
	NSObject* result = [win evaluateWebScript:command];
	if (!result || result == [WebUndefined undefined])
		NSLog(@"Nothing returned by script");
}

- (IBAction)prevAction:id
{
	WebScriptObject* win = [[webView mainFrame] windowObject];
	if (!win)
		return;
	[win evaluateWebScript:@"Mu.Songbird.playPrev();"];
}

- (IBAction)nextAction:id
{
	WebScriptObject* win = [[webView mainFrame] windowObject];
	if (!win)
		return;
	[win evaluateWebScript:@"Mu.Songbird.playNext();"];
}

- (IBAction)playPlaylistItem:id
{
    NSMenuItem* item = id;
    PlaylistTrack* track = [item representedObject];
    WebScriptObject* win = [[webView mainFrame] windowObject];
	if (!win)
		return;
	[win evaluateWebScript:[NSString stringWithFormat:@"Mu.Songbird.play(Mu.Songbird.playingList.trackEntryAt(%d));", track.index]]; 
}

// Used to send a URL to the user's default web browser. If they're holding down the <Shift> key,
// we'll send the URL without activating the receiving application.
- (BOOL) _sendBrowserRequest: (NSURLRequest*)request forAction: (NSDictionary*)actionInformation
{
    NSWorkspaceLaunchOptions options = NSWorkspaceLaunchDefault;
    unsigned modifiers = [[actionInformation objectForKey: WebActionModifierFlagsKey] unsignedIntValue];
    if( (modifiers & NSShiftKeyMask) )
        options |= NSWorkspaceLaunchWithoutActivation;
    BOOL ok = [[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject: [request URL]]
                              withAppBundleIdentifier: nil
                                              options: options
                       additionalEventParamDescriptor: nil
                                    launchIdentifiers: NULL];
    if( ! ok )
        NSBeep();
    return ok;
}


NSString* LOCAL_PREFIXES[] = {@"http://music.yandex.ru", @"http://passport.yandex.ru", 
	                          @"https://passport.yandex.ru", @"http://pass.yandex.ru", @"https://pass.yandex.ru", nil};

// Intercept link clicks, and send them to the web browser if the user Cmd-clicked
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
        request:(NSURLRequest *)request 
        frame:(WebFrame *)frame
		decisionListener:(id<WebPolicyDecisionListener>)listener
{
    WebNavigationType navType = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    unsigned modifiers = [[actionInformation objectForKey: WebActionModifierFlagsKey] unsignedIntValue];
	BOOL sendToBrowser = NO;
	
	if (navType == WebNavigationTypeLinkClicked) {
		if (modifiers & NSCommandKeyMask) {
			sendToBrowser = YES;
		}
		else {
			sendToBrowser = YES;
			NSString* url = [[request URL] absoluteString];
			NSString** prefix = LOCAL_PREFIXES;
			while (*prefix != nil) {
				if ([url hasPrefix:*prefix]) {
					sendToBrowser = NO;
					break;
				}
				++prefix;
			}
		}
	}
	
	if (sendToBrowser) {
		[self _sendBrowserRequest: request forAction: actionInformation];
        [listener ignore];
	}
    else {
        [listener use];
	}
}


// Intercept link clicks destined for new windows, and send them to the user's default web browser
- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request 
        newFrameName:(NSString *)frameName 
        decisionListener:(id<WebPolicyDecisionListener>)listener
{
    [self _sendBrowserRequest: request forAction: actionInformation];
    [listener ignore];
}

- (void)saveState
{
	[webView close];
}

@end

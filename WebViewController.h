#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface PlaylistTrack : NSObject
{
	int index;
	NSString* tid;
	NSString* title;
    BOOL current;
}

@property(assign) NSString* title;
@property(assign) NSString* tid;
@property(assign) int index;
@property(assign) BOOL current;

-(PlaylistTrack*) init;

@end


@interface WebViewController : NSObject {
	NSString* trackName;
	IBOutlet WebView * webView;
	@private
	NSTimer* titleUpdateTimer;
}

@property(assign) NSString* trackName;

- (IBAction)playAction:id;
- (IBAction)nextAction:id;
- (IBAction)prevAction:id;
- (IBAction)playPlaylistItem:id;
- (void)loadStartPage;
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame;
- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame;

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName 
decisionListener:(id<WebPolicyDecisionListener>)listener;

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request 
		  frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener;

- (void)saveState;
- (BOOL)isUndefined: (NSObject*)obj;
- (NSString *)safeConvertString: (NSObject*)obj;
- (int)safeConvertInt: (NSObject*)obj;
- (NSString*) getPlayerState:(WebScriptObject*)window;
- (NSArray*) fetchPlaylist;

@end

/*
 Copyright (c) 2011, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <MobileCoreServices/UTCoreTypes.h>

#import "AppDelegate.h"
#import "RestAPIExplorerViewController.h"
#import "SFJsonUtils.h"
#import "SFAccountManager.h"
#import "SFAuthenticationManager.h"
#import "SFOAuthInfo.h"

/*
 NOTE if you ever need to update these, you can obtain them from your Salesforce org,
 (When you are logged in as an org administrator, go to Setup -> Develop -> Remote Access -> New )
 */


// Fill these in when creating a new Remote Access client on Force.com 
static NSString * const RemoteAccessConsumerKey = @"3MVG9Iu66FKeHhINkB1l7xt7kR8czFcCTUhgoA8Ol2Ltf1eYHOU4SqQRSEitYFDUpqRWcoQ2.dBv_a1Dyu5xa";
static NSString * const OAuthRedirectURI        = @"testsfdc:///mobilesdk/detect/oauth/done";

@interface AppDelegate ()

- (void)logoutInitiated:(NSNotification *)notification;
- (void)setupRootViewController;

@end

@implementation AppDelegate

@synthesize window = _window;

- (id)init
{
    self = [super init];
    if (self) {
        [SFLogger setLogLevel:SFLogLevelDebug];
        [SFAccountManager setClientId:RemoteAccessConsumerKey];
        [SFAccountManager setRedirectUri:OAuthRedirectURI];
        [SFAccountManager setScopes:[NSSet setWithObjects:@"api", nil]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutInitiated:) name:kSFUserLogoutOccurred object:[SFAuthenticationManager sharedManager]];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSFUserLogoutOccurred object:[SFAuthenticationManager sharedManager]];
}

#pragma mark - App delegate lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    SFOAuthFlowSuccessCallbackBlock successBlock = ^(SFOAuthInfo *info) {
        [self setupRootViewController];
    };
    SFOAuthFlowFailureCallbackBlock failureBlock = ^(SFOAuthInfo *info, NSError *error) {
        [[SFAuthenticationManager sharedManager] logout];
    };
    [[SFAuthenticationManager sharedManager] loginWithCompletion:successBlock failure:failureBlock];
    
    return YES;
}

#pragma mark - Private methods

- (void)setupRootViewController
{
    RestAPIExplorerViewController *rootVC = [[RestAPIExplorerViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = rootVC;
}

- (void)logoutInitiated:(NSNotification *)notification
{
    [self log:SFLogLevelDebug msg:@"Logout notification received.  Resetting app."];
    
}

#pragma mark - Unit test helpers

- (void)exportTestingCredentials {
    //collect credentials and copy to pasteboard 
    SFOAuthCredentials *creds = [SFAccountManager sharedInstance].coordinator.credentials;
    NSDictionary *configDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                RemoteAccessConsumerKey, @"test_client_id", 
                                [SFAccountManager loginHost], @"test_login_domain",
                                OAuthRedirectURI, @"test_redirect_uri", 
                                creds.refreshToken,@"refresh_token",
                                [creds.instanceUrl absoluteString] , @"instance_url", 
                                @"__NOT_REQUIRED__",@"access_token",
                                nil];
    
    NSString *configJSON = [SFJsonUtils JSONRepresentation:configDict];
    UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];
    [gpBoard setValue:configJSON forPasteboardType:(NSString*)kUTTypeUTF8PlainText];
    
}

@end

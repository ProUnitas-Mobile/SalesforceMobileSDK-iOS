/*
 SFSDKLoginHostStorage.m
 SalesforceSDKCore

 Created by Kunal Chitalia on 1/22/16.
 Copyright (c) 2016-present, salesforce.com, inc. All rights reserved.

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

#import "SFSDKLoginHostStorage.h"
#import "SFSDKLoginHost.h"
#import "SFManagedPreferences.h"
#import "SFSDKResourceUtils.h"
#import <SalesforceSDKCommon/NSUserDefaults+SFAdditions.h>

@interface SFSDKLoginHostStorage ()

@property (nonatomic, strong) NSMutableArray *loginHostList;

@end

// Key under which the list of login hosts will be stored in the user defaults.
static NSString * const SFSDKLoginHostList = @"SalesforceLoginHostListPrefs";

// Key for the host.
static NSString * const SFSDKLoginHostKey = @"SalesforceLoginHostKey";

// Key for the name.
static NSString * const SFSDKLoginHostNameKey = @"SalesforceLoginHostNameKey";

@implementation SFSDKLoginHostStorage

@synthesize loginHostList = _loginHostList;

+ (SFSDKLoginHostStorage *)sharedInstance {
    static SFSDKLoginHostStorage *instance = nil;
    if (!instance) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.loginHostList = [NSMutableArray array];
        SFManagedPreferences *managedPreferences = [SFManagedPreferences sharedPreferences];
        SFSDKLoginHost *aldine = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Aldine ISD"] host:@"aldine.force.com/purple" deletable:NO];
        SFSDKLoginHost *harmony = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Harmony Public Schools"] host:@"harmony.purplesense.org/purple" deletable:NO];
        SFSDKLoginHost *hisd = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Houston ISD"] host:@"houstonisd.purplesense.org/purple" deletable:NO];
        SFSDKLoginHost *yellowstone = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Yellowstone Schools"] host:@"purplehou.force.com/purple" deletable:NO];
        SFSDKLoginHost *yesprep = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"YES Prep Public Schools"] host:@"yesprep.purplesense.org/purple" deletable:NO];
        SFSDKLoginHost *serviceProviders = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Service Providers"] host:@"purple-sense.force.com" deletable:NO];
//         SFSDKLoginHost *aldineSandbox = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Aldine ISD Sandbox"] host:@"tw-aldine.cs201.force.com/purple" deletable:NO];
//         SFSDKLoginHost *harmonySandbox = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Harmony Public Schools Sandbox"] host:@"tw-harmonyschools.cs36.force.com/purple" deletable:NO];
//         SFSDKLoginHost *hisdSandbox = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Houston ISD Sandbox"] host:@"tw-houstonisd.cs196.force.com/purple" deletable:NO];
//         SFSDKLoginHost *yellowstoneSandbox = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"Yellowstone Schools Sandbox"] host:@"tw-purplehou.cs36.force.com/purple" deletable:NO];
//         SFSDKLoginHost *yesprepSandbox = [SFSDKLoginHost hostWithName:[SFSDKResourceUtils localizedString:@"YES Prep Public Schools Sandbox"] host:@"tw-yesprep.cs203.force.com/purple" deletable:NO];

        // Add the Production and Sandbox login hosts, unless an MDM policy explicitly forbids this.
        if (!(managedPreferences.hasManagedPreferences && managedPreferences.onlyShowAuthorizedHosts)) {
            [self.loginHostList addObject:aldine];
            [self.loginHostList addObject:harmony];
            [self.loginHostList addObject:hisd];
            [self.loginHostList addObject:yellowstone];
            [self.loginHostList addObject:yesprep];
            [self.loginHostList addObject:serviceProviders];
//             [self.loginHostList addObject:aldineSandbox];
//             [self.loginHostList addObject:harmonySandbox];
//             [self.loginHostList addObject:hisdSandbox];
//             [self.loginHostList addObject:yellowstoneSandbox];
//             [self.loginHostList addObject:yesprepSandbox];
        }

        // Load from managed preferences (e.g. MDM).
        if (managedPreferences.hasManagedPreferences) {

            /*
             * If there are any existing login hosts, remove them as MDM should take
             * highest priority and only the hosts enforced by MDM should be in the list.
             */
            if ([self.loginHostList count] > 0) {
                [self removeAllLoginHosts];
            }
            NSArray *hostLabels = managedPreferences.loginHostLabels;
            [managedPreferences.loginHosts enumerateObjectsUsingBlock:^(NSString *loginHost, NSUInteger idx, BOOL *stop) {
                NSString *sanitizedLoginHost = [loginHost stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *hostLabel = hostLabels.count > idx ? hostLabels[idx] : loginHost;
                [self.loginHostList addObject:[SFSDKLoginHost hostWithName:hostLabel host:sanitizedLoginHost deletable:NO]];
            }];
            if (managedPreferences.onlyShowAuthorizedHosts) {
                return self;
            }
        } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SFDCOAuthLoginHost"]) {

            // Load from info.plist.
            NSString *customHost = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"SFDCOAuthLoginHost"];

            /*
             * Add the login host from info.plist if it doesn't exist already.
             * This also handles the case where the custom host configured
             * was changed between version updates of the application.
             */
            if (![self loginHostForHostAddress:customHost]) {
                [self.loginHostList removeAllObjects];
                NSString *sanitizedCustomHost = [customHost stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                SFSDKLoginHost *customLoginHost = [SFSDKLoginHost hostWithName:customHost host:sanitizedCustomHost deletable:NO];
                [self.loginHostList addObject:customLoginHost];
            }
        }

        // Load from the user defaults.
        NSArray *persistedList = [[NSUserDefaults msdkUserDefaults] objectForKey:SFSDKLoginHostList];
        if (persistedList) {
            for (NSDictionary *dic in persistedList) {
                [self.loginHostList addObject:[SFSDKLoginHost hostWithName:[dic objectForKey:SFSDKLoginHostNameKey] host:[dic objectForKey:SFSDKLoginHostKey] deletable:YES]];
            }
        }
    }
    return self;
}

- (void)save {
    NSMutableArray *persistedList = [NSMutableArray arrayWithCapacity:10];
    for (SFSDKLoginHost *host in self.loginHostList) {
        if (host.isDeletable) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            NSString *hostName = host.name ? : @"";
            NSString *hostAddress = host.host ? : hostName;
            [dic setObject:hostName forKey:SFSDKLoginHostNameKey];
            [dic setObject:hostAddress forKey:SFSDKLoginHostKey];
            [persistedList addObject:dic];
        }
    }
    [[NSUserDefaults msdkUserDefaults] setObject:persistedList forKey:SFSDKLoginHostList];
    [[NSUserDefaults msdkUserDefaults] synchronize];
}

- (void)addLoginHost:(SFSDKLoginHost *)loginHost {
    [self.loginHostList addObject:loginHost];
    [self save];
}

- (void)removeLoginHostAtIndex:(NSUInteger)index {
    [self.loginHostList removeObjectAtIndex:index];
    [self save];
}

- (NSUInteger)indexOfLoginHost:(SFSDKLoginHost *)host{
    if ([self.loginHostList containsObject:host]) {
        return [self.loginHostList indexOfObject:host];
    }
    return NSNotFound;
}

- (SFSDKLoginHost *)loginHostAtIndex:(NSUInteger)index {
    return [self.loginHostList objectAtIndex:index];
}

- (SFSDKLoginHost *)loginHostForHostAddress:(NSString *)hostAddress {
    for (SFSDKLoginHost *host in self.loginHostList) {
        if ([host.host isEqualToString:hostAddress]) {
            return host;
        }
    }
    return nil;
}

- (void)removeAllLoginHosts {
    SFManagedPreferences *managedPreferences = [SFManagedPreferences sharedPreferences];
    NSUInteger startingIndex = 2;

    /*
     * If MDM policy is set to hide hosts, 'Production' and 'Sandbox' won't be on the list.
     */
    if (managedPreferences.hasManagedPreferences && managedPreferences.onlyShowAuthorizedHosts) {
        startingIndex = 0;
    }
    [self.loginHostList removeObjectsInRange:NSMakeRange(startingIndex, [self.loginHostList count] - 2)];
}

- (NSUInteger)numberOfLoginHosts {
    return [self.loginHostList count];
}

@end

//
//  WhitelistHelper.m
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "WhitelistHelper.h"
#import "NSString+SSToolkitAdditions.h"

@implementation WhitelistHelper

+ (void)setProxyMode:(NSInteger)index
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setInteger:index forKey:@"proxy_mode"];
    [prefs synchronize];
}

+ (BOOL)isHostShouldProxy:(NSString *)host isProxyOn:(BOOL)isProxyOn
{
    if (!isProxyOn) {
        return NO;
    }
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger proxyMode = [prefs integerForKey:@"proxy_mode"];
    
    if (proxyMode==OW_PROXY_MODE_ALLSITES) {
        return YES;
    }
    
    if (proxyMode==OW_PROXY_MODE_DIRECT) {
        return NO;
    }
    
    NSArray *whitelist = [prefs objectForKey:@"whitelist"];
    
    for ( NSDictionary *site in whitelist ) {
        BOOL enabled = [site[@"enabled"] boolValue];
        
        if (!enabled) {
            continue;
        }
        
        NSString *address = site[@"address"];
        
        if ( NSOrderedSame == [host caseInsensitiveCompare:address] ) {
            return YES;
        }
        
        BOOL subdomains = [site[@"subdomains"] boolValue];
        
        if ( subdomains && [host.lowercaseString containsString:[NSString stringWithFormat:@".%@", address]] ) {
            return YES;
        }
    }
    
    return NO;
}

+ (NSDictionary *)newSite:(NSString *)siteHost
{
    NSMutableDictionary* site = [[NSMutableDictionary alloc] init];
    
    [site setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    [site setObject:[NSNumber numberWithBool:YES] forKey:@"subdomains"];
    
    if (siteHost) {
        [site setObject:siteHost forKey:@"address"];
    } else {
        [site setObject:@"example.com" forKey:@"address"];
    }
    
    return site;
}

#pragma mark - sites helper

+ (NSArray *)builtinSites
{
    // http://en.wikipedia.org/wiki/List_of_websites_blocked_in_the_People%27s_Republic_of_China
    
    return @[
             @[ // google
                 @"google.com",
                 @"googlecode.com",
                 @"google-analytics.com",
                 @"feedburner.com",
                 @"gmail.com",
                 @"appspot.com",
                 @"googleusercontent.com",
                 ],
             @[ // twitter
                 @"twitter.com",
                 @"twimg.com",
                 @"t.co",
                 ],
             @[ // facebook
                 @"facebook.com",
                 @"facebook.net",
                 @"ff.im",
                 @"fbcdn.net",
                 ],
             @[ // youtube
                 @"youtube.com",
                 @"youtu.be",
                 @"ytimg.com",
                 @"y2u.be",
                 ],
             @[ // blogger
                 @"blogger.com",
                 @"blogcdn.com",
                 @"blogspot.com",
                 ],
             @[ // wordpress
                 @"wordpress.com",
                 @"wp.com",
                 ],
             @[ // wikipedia
                 @"wikipedia.org",
                 @"wikimedia.org",
                 ],
             @[ // imdb
                 @"imdb.com",
                 ],
             @[ // vimeo
                 @"vimeo.com",
                 ],
             @[ // bbc
                 @"bbc.com",
                 @"bbc.co.uk",
                 @"bbci.co.uk",
                 @"imrworldwide.com",
                 ],
             @[ // nytimes
                 @"nytimes.com",
                 @"nyt.com",
                 @"typekit.com",
                 @"revsci.net",
                 @"scorecardresearch.com",
                 @"nytlog.com",
                 ],
             @[ // dropbox
                 @"dropbox.com",
                 ],
             @[ // url shortten
                 @"j.mp",
                 @"bit.ly",
                 @"bitly.com",
                 @"tinyurl.com",
                 @"ow.ly",
                 @"dft.ba",
                 @"goo.gl",
                 @"is.gd",
                 ],
             ];
}

@end

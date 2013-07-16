//
//  WhitelistHelper.m
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "WhitelistHelper.h"

@implementation WhitelistHelper

+ (void)setProxyMode:(NSInteger)index
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs synchronize];
    
    [prefs setInteger:index forKey:@"proxy_mode"];
    [prefs synchronize];
}

@end

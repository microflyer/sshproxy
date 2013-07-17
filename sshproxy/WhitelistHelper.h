//
//  WhitelistHelper.h
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    OW_PROXY_MODE_ALLSITES = 0,
    OW_PROXY_MODE_WHITELIST,
    OW_PROXY_MODE_DIRECT,
};

@interface WhitelistHelper : NSObject

+ (void)setProxyMode:(NSInteger)index;

+ (BOOL)isHostShouldProxy:(NSString *)host;

@end

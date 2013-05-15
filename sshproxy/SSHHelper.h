//
//  SSHHelper.h
//  sshproxy
//
//  Created by Brant Young on 15/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSHHelper : NSObject

// for ProxyCommand
+(NSString*) getProxyCommandStr;

+(NSMutableDictionary*) getProxyCommandEnv;

@end

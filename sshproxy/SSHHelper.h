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
+ (NSDictionary*) getProxyCommandEnv:(NSDictionary*) server;
+ (NSString*)getProxyCommandStr:(NSDictionary*) server;

+ (NSMutableArray*)getConnectArgs;

+ (NSDictionary*)getActivatedServer;
+ (NSInteger)getActivatedServerIndex;

+ (void)setActivatedServer:(int) index;

// code that upgrade user preferences from 13.04 to 13.05
+ (void)upgrade1:(NSArrayController*) serverArrayController;

@end

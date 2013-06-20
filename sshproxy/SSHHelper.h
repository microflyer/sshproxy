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

// for servers
+ (NSDictionary*)getActivatedServer;
+ (NSInteger)getActivatedServerIndex;
+ (void)setActivatedServer:(int) index;

// for local settings
+ (NSInteger)getLocalPort;


// code that upgrade user preferences from 13.04 to 13.05
+ (void)upgrade1:(NSArrayController*) serverArrayController;

// password helper
+ (BOOL) setPassword:(NSString*)newPassword forHost:(NSString*)hostname port:(int) hostport user:(NSString*) username;
+ (BOOL) deletePasswordForHost:(NSString*)hostname port:(int) hostport user:(NSString*) username;
+ (NSString*) passwordForHost:(NSString*)hostname port:(int) hostport user:(NSString*) username;

@end

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
+ (NSDictionary *) getProxyCommandEnv:(NSDictionary*) server;
+ (NSString *)getProxyCommandStr:(NSDictionary*) server;

+ (NSMutableArray *)getConnectArgs;

// for servers
+ (NSArray *)getServers;
+ (NSDictionary *)getActivatedServer;
+ (NSInteger)getActivatedServerIndex;
+ (void)setActivatedServer:(int) index;

// for local settings
+ (NSInteger)getLocalPort;


// code that upgrade user preferences from 13.04 to 13.05
+ (void)upgrade1:(NSArrayController *) serverArrayController;

// password helper
+ (BOOL)setPassword:(NSString *)newPassword forHost:(NSString*)hostname port:(int) hostport user:(NSString *) username;
+ (BOOL)setPassword:(NSString *)newPassword forServer:(NSDictionary *)server;

+ (BOOL)deletePasswordForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passwordForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passwordForServer:(NSDictionary *)server;

// getters for server parameters
+ (NSString *)hostFromServer:(NSDictionary *)server;
+ (int)portFromServer:(NSDictionary *)server;
+ (NSString *)userFromServer:(NSDictionary *)server;
+ (BOOL)isEnableCompress:(NSDictionary *)server;
+ (BOOL)isShareSOCKS:(NSDictionary *)server;
+ (NSString *)privatekeyFromServer:(NSDictionary *)server;

// setters for server parameters
+ (NSDictionary *)setPrivatekey:(NSString *)path ForServer:(NSDictionary *)server;

+ (NSArray *)promptPasswordForServer:(NSDictionary *)server;

@end

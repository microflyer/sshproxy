//
//  SSHHelper.h
//  sshproxy
//
//  Created by Brant Young on 15/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    OW_AUTH_METHOD_PASSWORD = 0,
    OW_AUTH_METHOD_PUBLICKEY,
} OW_AUTH_METHOD;

@interface SSHHelper : NSObject

+ (NSMutableArray*)getPasswordMethodConnectArgs;
+ (NSMutableArray*)getPublicKeyMethodConnectArgsForServer:(NSDictionary *)server;

// for ProxyCommand
+ (NSDictionary *) getProxyCommandEnv:(NSDictionary*)server;
+ (NSString *)getProxyCommandStr:(NSDictionary*)server;

// for servers
+ (NSArray *)getServers;
+ (NSDictionary *)getActivatedServer;
+ (NSInteger)getActivatedServerIndex;
+ (void)setActivatedServer:(int) index;

// for local settings
+ (NSInteger)getLocalPort;


// code that upgrade user preferences from 13.04 to 13.05
+ (void)upgrade1:(NSArrayController *)serverArrayController;

// password helper
+ (BOOL)setPassword:(NSString *)newPassword forHost:(NSString*)hostname port:(int) hostport user:(NSString *) username;
+ (BOOL)setPassword:(NSString *)newPassword forServer:(NSDictionary *)server;

+ (BOOL)deletePasswordForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passwordForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passwordForServer:(NSDictionary *)server;

// passphrase helper
+ (BOOL)setPassphrase:(NSString *)newPassphrase forHost:(NSString*)hostname port:(int) hostport user:(NSString *) username;
+ (BOOL)setPassphrase:(NSString *)newPassphrased forServer:(NSDictionary *)server;

+ (BOOL)deletePassphraseForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passphraseForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passphraseForServer:(NSDictionary *)server;

// getters for server parameters
+ (NSString *)hostFromServer:(NSDictionary *)server;
+ (int)portFromServer:(NSDictionary *)server;
+ (int)authMethodFromServer:(NSDictionary *)server;
+ (NSString *)userFromServer:(NSDictionary *)server;
+ (BOOL)isEnableCompress:(NSDictionary *)server;
+ (BOOL)isShareSOCKS:(NSDictionary *)server;
+ (NSString *)privateKeyPathFromServer:(NSDictionary *)server;

+ (NSString *)importedPrivateKeyPathFromServer:(NSDictionary *)server;

// setters for server parameters
+ (NSDictionary *)setPrivateKeyPath:(NSString *)path forServer:(NSDictionary *)server;

+ (NSArray *)promptPasswordForServer:(NSDictionary *)server;

@end

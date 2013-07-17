//
//  SSHHelper.h
//  sshproxy
//
//  Created by Brant Young on 15/5/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

#define OW_SSHPROXY_ASKPASS_LOCK @".sshproxy_askpass_lock"
#define OW_SSHPROXY_DECRYPT_LOCK @".sshproxy_decrypt_lock"

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
+ (NSInteger)getSSHLocalPort;


// code that upgrade user preferences from 13.04 to 13.05
+ (void)upgrade1:(NSArrayController *)serverArrayController;

// getters for server parameters
+ (NSString *)hostFromServer:(NSDictionary *)server;
+ (int)portFromServer:(NSDictionary *)server;
+ (int)authMethodFromServer:(NSDictionary *)server;
+ (NSString *)userFromServer:(NSDictionary *)server;
+ (BOOL)isEnableCompress:(NSDictionary *)server;
+ (BOOL)isShareSOCKS:(NSDictionary *)server;
+ (NSString *)privateKeyPathFromServer:(NSDictionary *)server;

+ (NSString *)importedPrivateKeyPathFromServer:(NSDictionary *)server;
+ (NSString *)importedPrivateKeyNameFromServer:(NSDictionary *)server;

// setters for server parameters
+ (NSDictionary *)setPrivateKeyPath:(NSString *)path forServer:(NSDictionary *)server;


+ (NSString *)encryptServerInfo:(NSDictionary *)server;
+ (NSDictionary *)decryptServerInfo:(NSString *)encryptedServerInfo forDir:(NSString *)dir;

@end

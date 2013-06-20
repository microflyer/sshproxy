//
//  SSHHelper.m
//  sshproxy
//
//  Created by Brant Young on 15/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "SSHHelper.h"
#import "EMKeychain.h"

@implementation SSHHelper


+ (NSMutableArray*) getConnectArgs
{
    NSString* userHome = NSHomeDirectory();
    NSString* knownHostFile = @"/dev/null";
//    NSString* knownHostFile= [userHome stringByAppendingPathComponent:@".sshproxy_known_hosts"];
    NSString* identityFile= [userHome stringByAppendingPathComponent:@".sshproxy_identity"];
    //    NSString* configFile= [userHome stringByAppendingPathComponent:@".sshproxy_config"];
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
                                 [NSString stringWithFormat:@"-oUserKnownHostsFile=\"%@\"", knownHostFile],
                                 [NSString stringWithFormat:@"-oGlobalKnownHostsFile=\"%@\"", knownHostFile],
                                 [NSString stringWithFormat:@"-oIdentityFile=\"%@\"", identityFile],
                                 // TODO:
                                 //                        [NSString stringWithFormat:@"-F \"%@\"", configFile],
                                 @"-oIdentitiesOnly=yes",
                                 @"-oPubkeyAuthentication=no",
                                 @"-T", @"-a",
                                 @"-oConnectTimeout=8", @"-oConnectionAttempts=1",
                                 @"-oServerAliveInterval=8", @"-oServerAliveCountMax=1",
                                 @"-oStrictHostKeyChecking=no", @"-oExitOnForwardFailure=yes",
                                 @"-oNumberOfPasswordPrompts=1", @"-oLogLevel=DEBUG",
                                 nil];
    
    return arguments;
}

// for ProxyCommand Env
+ (NSDictionary*) getProxyCommandEnv:(NSDictionary*) server
{
    NSMutableDictionary* env = [NSMutableDictionary dictionary];
    
    BOOL proxyCommand = [(NSNumber *)[server valueForKey:@"proxy_command"] boolValue];
    BOOL proxyCommandAuth = [(NSNumber *)[server valueForKey:@"proxy_command_auth"] boolValue];
    
    NSString* proxyCommandUsername = (NSString *)[server valueForKey:@"proxy_command_username"];
    NSString* proxyCommandPassword = (NSString *)[server valueForKey:@"proxy_command_password"];
    
    if (proxyCommand && proxyCommandAuth) {
        if (proxyCommandUsername) {
            [env setValue:@"YES" forKey:@"HTTP_PROXY_FORCE_AUTH"];
            [env setValue:proxyCommandUsername forKey:@"CONNECT_USER"];
            if (proxyCommandPassword) {
                [env setValue:proxyCommandPassword forKey:@"CONNECT_PASSWORD"];
            }
        }
    }
    
    return env;
}

// for ProxyCommand
+ (NSString*)getProxyCommandStr:(NSDictionary*) server
{
    NSString *connectPath = [NSBundle pathForResource:@"connect" ofType:@""
                                          inDirectory:[[NSBundle mainBundle] bundlePath]];
    
    BOOL proxyCommand = [(NSNumber *)[server valueForKey:@"proxy_command"] boolValue];
    int proxyCommandType = [(NSNumber *)[server valueForKey:@"proxy_command_type"] intValue];
    NSString* proxyCommandHost = (NSString *)[server valueForKey:@"proxy_command_host"];
    int proxyCommandPort = [(NSNumber *)[server valueForKey:@"proxy_command_port"] intValue];
    
    NSString* proxyCommandStr = nil;
    if (proxyCommand){
        if (proxyCommandHost) {
            NSString* proxyType = @"-S";
            
            switch (proxyCommandType) {
                case 0:
                    proxyType = @"-5 -S";
                    break;
                case 1:
                    proxyType = @"-4 -S";
                    break;
                case 2:
                    proxyType = @"-H";
                    break;
            }
            
            if (proxyCommandPort<=0 || proxyCommandPort>65535) {
                proxyCommandPort = 1080;
            }
            
            proxyCommandStr = [NSString stringWithFormat:@"-oProxyCommand=\"%@\" -d -w 8 %@ %@:%d %@", connectPath, proxyType, proxyCommandHost, proxyCommandPort, @"%h %p"];
        }
    }
    
    return proxyCommandStr;
}

+ (NSInteger) getActivatedServerIndex
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSArray* servers = [prefs arrayForKey:@"servers"];
    NSInteger index = [prefs integerForKey:@"activated_server"];
    
    if (index<0 || index>=servers.count) {
        index = 0;
    }
    
    return index;
}

+ (NSDictionary*) getActivatedServer
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSArray* servers = [prefs arrayForKey:@"servers"];
    
    if ( [servers count]<=0 ){
        return nil;
    }
    
    NSInteger index = [SSHHelper getActivatedServerIndex];
    return servers[index];
}

+ (void) setActivatedServer:(int) index
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:index forKey:@"activated_server"];
    [prefs synchronize];
}

// code that upgrade user preferences from 13.04 to 13.05
+ (void)upgrade1:(NSArrayController*) serverArrayController
{
    // fetch preferences that need upgrade
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString* remoteHost = [prefs stringForKey:@"remote_host"];
    if (!remoteHost) {
        // do not need upgrade
        return;
    }
    
    NSString* loginName = [prefs stringForKey:@"login_name"];
    if (!loginName) {
        loginName = @"";
    }
    
    int remotePort = (int)[prefs integerForKey:@"remote_port"];
    if (remotePort<=0 || remotePort>65535) {
        remotePort = 22;
    }
    
    BOOL enableCompression = [prefs boolForKey:@"enable_compression"];
    BOOL shareSocks = [prefs boolForKey:@"share_socks"];
    
    BOOL proxyCommand = [prefs boolForKey:@"proxy_command"];
    int proxyCommandType = (int)[prefs integerForKey:@"proxy_command_type"];
    NSString* proxyCommandHost = (NSString*)[prefs stringForKey:@"proxy_command_host"];
    int proxyCommandPort = (int)[prefs integerForKey:@"proxy_command_port"];
    
    if (proxyCommandPort<=0 || proxyCommandPort>65535) {
        proxyCommandPort = 1080;
    }
    
    BOOL proxyCommandAuth = [prefs boolForKey:@"proxy_command_auth"];
    NSString* proxyCommandUsername = [prefs stringForKey:@"proxy_command_username"];
    NSString* proxyCommandPassword = [prefs stringForKey:@"proxy_command_password"];
    
    // upgrade
    
    NSMutableDictionary* server = [[NSMutableDictionary alloc] init];
    
    [server setObject:remoteHost forKey:@"remote_host"];
    [server setObject:[NSNumber numberWithInt:remotePort] forKey:@"remote_port"];
    [server setObject:loginName forKey:@"login_name"];
    [server setObject:[NSNumber numberWithBool:enableCompression] forKey:@"enable_compression"];
    [server setObject:[NSNumber numberWithBool:shareSocks] forKey:@"share_socks"];
    
    [server setObject:[NSNumber numberWithBool:proxyCommand] forKey:@"proxy_command"];
    [server setObject:[NSNumber numberWithBool:proxyCommandType] forKey:@"proxy_command_type"];
    if (proxyCommandHost) [server setObject:proxyCommandHost forKey:@"proxy_command_host"];
    [server setObject:[NSNumber numberWithInt:proxyCommandPort] forKey:@"proxy_command_port"];
    
    
    [server setObject:[NSNumber numberWithBool:proxyCommandAuth] forKey:@"proxy_command_auth"];
    if (proxyCommandUsername) [server setObject:proxyCommandUsername forKey:@"proxy_command_username"];
    if (proxyCommandPassword) [server setObject:proxyCommandPassword forKey:@"proxy_command_password"];
    
    [serverArrayController addObject:server];
    
    // remove old preferences
    
    [prefs removeObjectForKey:@"remote_host"];
    [prefs removeObjectForKey:@"remote_port"];
    [prefs removeObjectForKey:@"login_name"];
    
    [prefs removeObjectForKey:@"enable_compression"];
    [prefs removeObjectForKey:@"share_socks"];
    
    [prefs removeObjectForKey:@"proxy_command"];
    [prefs removeObjectForKey:@"proxy_command_type"];
    [prefs removeObjectForKey:@"proxy_command_host"];
    [prefs removeObjectForKey:@"proxy_command_port"];
    
    [prefs removeObjectForKey:@"proxy_command_auth"];
    [prefs removeObjectForKey:@"proxy_command_username"];
    [prefs removeObjectForKey:@"proxy_command_password"];
    
    [prefs synchronize];
}


#pragma mark -
#pragma mark Password Helper

//! Simply looks for the keychain entry corresponding to a username and hostname and returns it. Returns nil if the password is not found
+ (NSString*) passwordForHost:(NSString*)hostName port:(int) hostPort user:(NSString*) userName
{
	if ( hostName == nil || userName == nil ){
		return nil;
	}
	
	EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer:hostName withUsername:userName path:nil port:hostPort protocol:kSecProtocolTypeSSH];
    
    return keychainItem ? keychainItem.password : nil;
}



/*! Set the password into the keychain for a specific user and host. If the username/hostname combo already has an entry in the keychain then change it. If not then add a new entry */
+ (BOOL) setPassword:(NSString*)newPassword forHost:(NSString*)hostName port:(int) hostPort user:(NSString*) userName
{
	if ( hostName == nil || userName == nil ) {
		return NO;
	}
	
	// Look for a password in the keychain
    EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer:hostName withUsername:userName path:nil port:hostPort protocol:kSecProtocolTypeSSH];
    
    if (!keychainItem) {
        keychainItem = [EMInternetKeychainItem addInternetKeychainItemForServer:hostName withUsername:userName password:newPassword path:nil port:hostPort protocol:kSecProtocolTypeSSH];
        return NO;
    }
    
    keychainItem.password = newPassword;
    return YES;
}

+ (BOOL) deletePasswordForHost:(NSString*)hostName port:(int) hostPort user:(NSString*) userName
{
	if ( hostName == nil || userName == nil ) {
		return NO;
	}
    
	// Look for a password in the keychain
    EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer:hostName withUsername:userName path:nil port:hostPort protocol:kSecProtocolTypeSSH];
    
    if (!keychainItem) {
        return NO;
    }
    
    [EMInternetKeychainItem removeKeychainItem:keychainItem];
    return YES;
}

#pragma mark Local Settings

+ (NSInteger)getLocalPort
{
    NSInteger localPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
    
    if (localPort<=0 || localPort>65535) {
        localPort = 7070;
    }
    
    return localPort;
}

@end

//
//  SSHHelper.m
//  sshproxy
//
//  Created by Brant Young on 15/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "SSHHelper.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "NSString+SSToolkitAdditions.h"
#import "NSData+SSToolkitAdditions.h"
#import "NSDictionary+SSToolkitAdditions.h"

@implementation SSHHelper

+ (NSMutableArray*)_getCommonConnectArgs
{
    NSString* knownHostFile = @"/dev/null";
    //    NSString* knownHostFile= [userHome stringByAppendingPathComponent:@".sshproxy_known_hosts"];
//    NSString* configFile= [NSHomeDirectory() stringByAppendingPathComponent:@".sshproxy_config"];
    
    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
                                 [NSString stringWithFormat:@"-oUserKnownHostsFile=\"%@\"", knownHostFile],
                                 [NSString stringWithFormat:@"-oGlobalKnownHostsFile=\"%@\"", knownHostFile],
                                 // TODO:
//                                 [NSString stringWithFormat:@"-F \"%@\"", configFile],
                                 @"-oIdentitiesOnly=yes",
                                 @"-oPubkeyAuthentication=yes",
                                 @"-oAskPassGUI=no", // TODO: OS X 10.6 may fail
                                 @"-T", @"-a",
                                 @"-oConnectTimeout=8", @"-oConnectionAttempts=1",
                                 @"-oServerAliveInterval=8", @"-oServerAliveCountMax=1",
                                 @"-oStrictHostKeyChecking=no", @"-oExitOnForwardFailure=yes",
                                 @"-oNumberOfPasswordPrompts=3", @"-oLogLevel=DEBUG",
                                 nil];
    
    return arguments;
}

+ (NSMutableArray*)getPasswordMethodConnectArgs
{
    NSMutableArray *arguments = [self _getCommonConnectArgs];
    
    [arguments addObjectsFromArray:@[
     @"-oPreferredAuthentications=keyboard-interactive,password",
     @"-oPubkeyAuthentication=no"]
     ];
    
    return arguments;
}

+ (NSMutableArray*)getPublicKeyMethodConnectArgsForServer:(NSDictionary *)server
{
    NSString* privateKeyPath= [self importedPrivateKeyPathFromServer:server];
    
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:privateKeyPath isDirectory:NO] ) {
        // return nil if imported private key miss
        return nil;
    }
    
    NSMutableArray *arguments = [self _getCommonConnectArgs];
    
    [arguments addObjectsFromArray:@[
     [NSString stringWithFormat:@"-oIdentityFile=\"%@\"", privateKeyPath],
     @"-oPreferredAuthentications=publickey",
     @"-oPubkeyAuthentication=yes"]
     ];
    
    return arguments;
}

// for ProxyCommand Env
+ (NSDictionary*) getProxyCommandEnv:(NSDictionary *)server
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

+ (NSArray *)getServers
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs synchronize];
    
    return [[NSUserDefaults standardUserDefaults] arrayForKey:@"servers"];
}

+ (void)setServers:(NSMutableArray *) servers
{
    [[NSUserDefaults standardUserDefaults] arrayForKey:@"servers"];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs synchronize];
}

+ (NSInteger) getActivatedServerIndex
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs synchronize];
    
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
    [prefs synchronize];
    
    NSArray* servers = [prefs arrayForKey:@"servers"];
    
    if ( [servers count]<=0 ){
        return nil;
    }
    
    NSInteger index = [SSHHelper getActivatedServerIndex];
    return [servers objectAtIndex:index];
}

+ (void) setActivatedServer:(int) index
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs synchronize];
    
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

#pragma mark - Local Settings

+ (NSInteger)getLocalPort
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger localPort = [prefs integerForKey:@"local_port"];
    [prefs synchronize];
    
    if (localPort<=0 || localPort>65535) {
        localPort = 7070;
    }
    
    return localPort;
}

#pragma mark Getters for server parameters

+ (NSString *)hostFromServer:(NSDictionary *)server
{
    NSString* remoteHost = (NSString *)[server valueForKey:@"remote_host"];
    
    if (!remoteHost) {
        remoteHost = @"";
    }
    
    return remoteHost;
}

+ (int)portFromServer:(NSDictionary *)server
{
    int remotePort = [(NSNumber*)[server valueForKey:@"remote_port"] intValue];
    
    if (remotePort<=0 || remotePort>65535) {
        remotePort = 22;
    }
    
    return remotePort;
}
+ (int)authMethodFromServer:(NSDictionary *)server
{
    int authMethod = [(NSNumber*)[server valueForKey:@"auth_method"] intValue];
    
    return authMethod;
}

+ (NSString *)userFromServer:(NSDictionary *)server
{
    NSString* loginName = (NSString *)[server valueForKey:@"login_name"];
    
    if (!loginName) {
        loginName = @"";
    }
    
    return loginName;
}

+ (NSString *)privateKeyPathFromServer:(NSDictionary *)server
{
    NSString* privatekey = (NSString *)[server valueForKey:@"privatekey_path"];
    
    if (!privatekey) {
        privatekey = @"";
    }
    
    return privatekey;
}
+ (NSString *)importedPrivateKeyNameFromServer:(NSDictionary *)server
{
    NSString *origPrivateKeyPath = [self privateKeyPathFromServer:server];
    
    return [origPrivateKeyPath MD5Sum];
}
+ (NSString *)importedPrivateKeyPathFromServer:(NSDictionary *)server
{
    // create ".ssh" dir at sandbox container
    NSString *importedKeyDir = [NSHomeDirectory() stringByAppendingPathComponent:@".ssh"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:importedKeyDir])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:importedKeyDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
        
    NSString *importedKeyName = [self importedPrivateKeyNameFromServer:server];
    NSString *importedKeyPath = [importedKeyDir stringByAppendingPathComponent:importedKeyName];
    
    return importedKeyPath;
}

+ (BOOL)isEnableCompress:(NSDictionary *)server
{
    return [(NSNumber*)[server valueForKey:@"enable_compression"] boolValue];
}
+ (BOOL)isShareSOCKS:(NSDictionary *)server
{
    return [(NSNumber*)[server valueForKey:@"share_socks"] boolValue];
}

#pragma mark setters

+ (NSDictionary *)setPrivateKeyPath:(NSString *)path forServer:(NSDictionary *)server
{
    [server setValue:path forKey:@"privatekey_path"];
    return server;
}

#pragma mark - Server info encrypt / decrypt

+ (NSString *)encryptServerInfo:(NSDictionary *)server
{
    NSString* userHome = NSHomeDirectory();
    NSString* lockFile= [userHome stringByAppendingPathComponent:OW_SSHPROXY_DECRYPT_LOCK];
    NSString* serverInfo = [server stringWithFormEncodedComponents];
    
    // touch lock file
    {
        // [[NSFileManager defaultManager] createFileAtPath:lockFile contents:nil attributes: nil];
        // use plain c to avoid create unprivileged cache file
        FILE *fh = fopen([lockFile UTF8String], "w");
        fclose(fh);
    }
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:lockFile error:nil];
    NSString *digest = attributes ? [attributes.description MD5Sum] : [lockFile MD5Sum];
    
    NSData *data = [serverInfo dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    
    NSData *encryptedData = [RNEncryptor encryptData: data
                                        withSettings: kRNCryptorAES256Settings
                                            password: digest
                                               error: &error];
    
    return [encryptedData base64EncodedString];
}
+ (NSDictionary *)decryptServerInfo:(NSString *)encryptedServerInfo forDir:(NSString *)dir
{
    NSString* lockFile= [dir stringByAppendingPathComponent:OW_SSHPROXY_DECRYPT_LOCK];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:lockFile error:nil];
    NSString *digest = attributes ? [attributes.description MD5Sum] : [lockFile MD5Sum];
    
    NSData *encryptedData = [NSData dataWithBase64String:encryptedServerInfo ];
    NSError *error;
    NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                            withPassword:digest
                                                   error:&error];
    
    NSString *serverInfo = [[NSString alloc] initWithData:decryptedData
                                               encoding:NSUTF8StringEncoding];
    return [NSDictionary dictionaryWithFormEncodedString:serverInfo];;
}


@end


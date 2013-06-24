//
//  PasswordHelper.m
//  sshproxy
//
//  Created by Brant Young on 21/6/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "PasswordHelper.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "NSData+SSToolkitAdditions.h"
#import "NSString+SSToolkitAdditions.h"

@implementation PasswordHelper

+ (NSString *)encryptPassword:(NSString *)password
{
    return password;
    NSString* userHome = NSHomeDirectory();
    NSString* lockFile= [userHome stringByAppendingPathComponent:@".sshproxy_askpass_lock"];
    
    // touch lock file
    {
        // [[NSFileManager defaultManager] createFileAtPath:lockFile contents:nil attributes: nil];
        // use plain c to avoid create unprivileged cache file
        FILE *fh = fopen([lockFile UTF8String], "w");
        fclose(fh);
    }
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:lockFile error:nil];
    NSString *digest = attributes ? [attributes.description MD5Sum] : [lockFile MD5Sum];
    
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    
    NSData *encryptedData = [RNEncryptor encryptData: data
                                        withSettings: kRNCryptorAES256Settings
                                            password: digest
                                               error: &error];
    
    NSString *encryptedPassword = [encryptedData base64EncodedString];
    
    return encryptedPassword;
}
+ (NSString *)decryptPassword:(NSString *)encryptedPassword forDir:(NSString *)dir
{
    return encryptedPassword;
    NSString* lockFile= [dir stringByAppendingPathComponent:@".sshproxy_askpass_lock"];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:lockFile error:nil];
    NSString *digest = attributes ? [attributes.description MD5Sum] : [lockFile MD5Sum];
    
    NSData *encryptedData = [NSData dataWithBase64String:encryptedPassword ];
    NSError *error;
    NSData *decryptedPassword = [RNDecryptor decryptData:encryptedData
                                            withPassword:digest
                                                   error:&error];
    NSString *password = [[NSString alloc] initWithData:decryptedPassword
                                 encoding:NSUTF8StringEncoding];
    return password;
}

@end

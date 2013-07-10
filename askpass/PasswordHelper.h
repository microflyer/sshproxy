//
//  PasswordHelper.h
//  sshproxy
//
//  Created by Brant Young on 21/6/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PasswordHelper : NSObject

// password helper
+ (BOOL)setPassword:(NSString *)newPassword forHost:(NSString*)hostname port:(int) hostport user:(NSString *) username;
+ (BOOL)setPassword:(NSString *)newPassword forServer:(NSDictionary *)server;

+ (BOOL)deletePasswordForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passwordForHost:(NSString *)hostname port:(int) hostport user:(NSString *) username;
+ (NSString *)passwordForServer:(NSDictionary *)server;

// passphrase helper
+ (BOOL)setPassphrase:(NSString *)newPassphrased forServer:(NSDictionary *)server;
+ (BOOL)deletePassphraseForServer:(NSDictionary *)server;
+ (NSString *)passphraseForServer:(NSDictionary *)server;

+ (NSArray *)promptPasswordForServer:(NSDictionary *)server;

@end

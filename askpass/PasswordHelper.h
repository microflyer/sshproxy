//
//  PasswordHelper.h
//  sshproxy
//
//  Created by Brant Young on 21/6/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PasswordHelper : NSObject

+ (NSString *)encryptPassword:(NSString *)password;
+ (NSString *)decryptPassword:(NSString *)encryptedPassword forDir:(NSString *)dir;

@end

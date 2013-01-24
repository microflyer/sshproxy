//
//   PasswordHelper.h
//
//  Created by Ira Cooke on 27/07/2009.
//  Copyright 2009 Mudflat Software. 
//

#import <Cocoa/Cocoa.h>

/*! This class consists entirely of class methods which provide a simple interface to keychain calls to set and retrieve passwords*/
@interface PasswordHelper : NSObject {
}

+ (BOOL) setPassword:(NSString*)newPassword forHost:(NSString*)hostname port:(int) hostport user:(NSString*) username;
+ (NSString*) passwordForHost:(NSString*)hostname port:(int) hostport user:(NSString*) username;
+ (NSArray *) promptForPassword:(NSString*)hostname port:(int) hostport user:(NSString*) username;


@end

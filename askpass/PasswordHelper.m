//
//  PasswordHelper.m
//
//  Created by Ira Cooke on 27/07/2009.
//  Copyright 2009 Mudflat Software.
//  Copyright (c) 2013 Codinn Studio.
//

#import "PasswordHelper.h"
#import "EMKeychain.h"


@implementation PasswordHelper



+ (NSArray *) promptForPassword:(NSString*)hostname port:(int) hostport user:(NSString*) username
{
	CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef passwordRef;
	
	NSMutableArray *returnArray = [NSMutableArray arrayWithObjects:@"PasswordString",[NSNumber numberWithInt:0],[NSNumber numberWithInt:1],nil];
    
    NSString* hostString = [NSString stringWithFormat:@"%@@%@:%d", username, hostname, hostport];
	
	NSString *passwordMessageString = [NSString stringWithFormat:@"Enter the password for user “%@”.",
                                       hostString];
    
    NSString* headerString = [NSString stringWithFormat:@"SSH Proxy connecting to the SSH server “%@”.",
                              hostString];
                              
	
	NSDictionary *panelDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               headerString,kCFUserNotificationAlertHeaderKey,
                               passwordMessageString,kCFUserNotificationAlertMessageKey,
							   @"",kCFUserNotificationTextFieldTitlesKey,
							   @"Cancel",kCFUserNotificationAlternateButtonTitleKey,
                               @"Remember this password in my keychain",kCFUserNotificationCheckBoxTitlesKey,
							   nil];
	
	passwordDialog = CFUserNotificationCreate(kCFAllocatorDefault,
											  0,
											  kCFUserNotificationPlainAlertLevel
											  | CFUserNotificationSecureTextField(0)
                                              | CFUserNotificationCheckBoxChecked(0),
											  &error,
											  (__bridge CFDictionaryRef)panelDict);
	
	
	if (error){
		// There was an error creating the password dialog
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:error]];
		return returnArray;
	}
	
	error = CFUserNotificationReceiveResponse(passwordDialog,
											  0,
											  &responseFlags);

	if (error){
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:error]];
		return returnArray;
	}
	
	
	button = responseFlags & 0x3;
	if (button == kCFUserNotificationAlternateResponse) {
		CFRelease(passwordDialog);
		[returnArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:1]];
		return returnArray;		
	}
	
	if ( responseFlags & CFUserNotificationCheckBoxChecked(0) ){
		[returnArray replaceObjectAtIndex:2 withObject:[NSNumber numberWithInt:0]];
	}
	passwordRef = CFUserNotificationGetResponseValue(passwordDialog,
													 kCFUserNotificationTextFieldValuesKey,
													 0);
	
	
	[returnArray replaceObjectAtIndex:0 withObject:(__bridge NSString*)passwordRef];
	CFRelease(passwordDialog); // Note that this will release the passwordRef as well
	return returnArray;	
}


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

@end

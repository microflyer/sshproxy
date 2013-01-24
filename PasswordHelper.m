//
//  PasswordHelper.m
//
//  Created by Ira Cooke on 27/07/2009.
//  Copyright 2009 Mudflat Software. 
//

#import "PasswordHelper.h"

@interface PasswordHelper (Private)
// These are convenience methods (see bottom of page). They are largely based on apple's examples and are simplified wrappers for C functions in the keychain API.
+ (OSStatus) storePasswordKeychain:(NSString*)password host:(NSString*) hostnameStr port:(int)hostport user:(NSString*) usernameStr;
+ (OSStatus) getPasswordKeychain:(void*)passwordData length:(UInt32*) passwordLength itemRef:(SecKeychainItemRef *)itemRef host:(NSString*) hostnameStr port:(int) hostport user:(NSString*) usernameStr;
+ (OSStatus) changePasswordKeychain:(SecKeychainItemRef)itemRef password:(NSString*) newPassword;
@end


@implementation PasswordHelper



+ (NSArray *) promptForPassword:(NSString*)hostname port:(int) hostport user:(NSString*) username {
	CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef passwordRef;
	
	NSMutableArray *returnArray = [NSMutableArray arrayWithObjects:@"PasswordString",[NSNumber numberWithInt:0],[NSNumber numberWithInt:1],nil];
    
    NSString* hostString = [NSString stringWithFormat:@"%@@%@:%d", username, hostname, hostport];
	
	NSString *passwordMessageString = [NSString stringWithFormat:@"Enter the password for user “%@”.",
                                       hostString];
    
    NSString* headerString = [NSString stringWithFormat:@"Charm SSH Proxy connecting to the SSH server “%@”.",
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
+ (NSString*) passwordForHost:(NSString*)hostnameStr port:(int) hostport user:(NSString*) usernameStr {
	if ( hostnameStr == nil || usernameStr == nil ){
		return nil;
	}
	
	UInt32 passwordLen=0; 
	void *passwordData = NULL;
	SecKeychainItemRef itemRef = NULL;
		
	// Look for a password in the keychain
	OSStatus findKeychainItemStatus = [PasswordHelper getPasswordKeychain:&passwordData length:&passwordLen itemRef:&itemRef host:hostnameStr port:hostport user:usernameStr];
	
	if ( findKeychainItemStatus == noErr ){
		NSString *returnString = [[NSString alloc] initWithBytes:passwordData
														  length:passwordLen encoding:NSUTF8StringEncoding];
		SecKeychainItemFreeContent(NULL,passwordData);
		return returnString;
	} else {
		return nil;
	}
	
}



/*! Set the password into the keychain for a specific user and host. If the username/hostname combo already has an entry in the keychain then change it. If not then add a new entry */
+ (BOOL) setPassword:(NSString*)newPassword forHost:(NSString*)hostname port:(int) hostport user:(NSString*) username {
	
	if ( hostname == nil || username == nil ){
		return NO;
	}
	
	// Look for a password in the keychain
	SecKeychainItemRef itemRef = nil;
	UInt32 passwordLen = 0; 
	void *passwordData = NULL;
	
	OSStatus findKeychainItemStatus;
	findKeychainItemStatus = [PasswordHelper getPasswordKeychain:&passwordData length:&passwordLen itemRef:&itemRef host:hostname port:hostport user:username];
	
	if ( findKeychainItemStatus == noErr ){
		// The keychain item already exists but it needs to be updated
		
		[PasswordHelper changePasswordKeychain:itemRef password:newPassword];
		SecKeychainItemFreeContent(NULL,passwordData);
		return YES;
	} else {
		[PasswordHelper storePasswordKeychain:newPassword host:hostname port:hostport user:username];
		return YES;
	}
}


#pragma mark simple wrappers for keychain access functions

//! Add an internet password to the default keychain. 
+ (OSStatus) storePasswordKeychain:(NSString*) passwordStr
							  host:(NSString*) hostnameStr
                              port:(int) hostport
							  user:(NSString*) usernameStr
{
	UInt32 passwordLength=(UInt32)[passwordStr length];
	void* password = (void*)[passwordStr UTF8String];
	
	UInt32 hostnameLength = (UInt32)[hostnameStr length];
	const char* hostname=[hostnameStr UTF8String];
	UInt32 usernameLength = (UInt32)[usernameStr length];
	const char* username=[usernameStr UTF8String];
	
	return SecKeychainAddInternetPassword(NULL,
										  hostnameLength,
										  hostname,
										  0,
										  NULL,
										  usernameLength,
										  username,
										  strlen(""),
										  "",
										  hostport,
										  kSecProtocolTypeSSH,
										  kSecAuthenticationTypeDefault,
										  passwordLength,
										  password,
										  NULL);
	
}

//! Get password from the keychain. If this succeeds it allocates password data and must therefore be followed by a call to SecKeychainItemFreeContent
+ (OSStatus) getPasswordKeychain:(void*)passwordData 
						  length:(UInt32*) passwordLength 
						 itemRef:(SecKeychainItemRef *)itemRef 
							host:(NSString*) hostnameStr
                            port:(int) hostport
							user:(NSString*) usernameStr
{
	UInt32 hostnameLength = (UInt32)[hostnameStr length];
	const char* hostname=[hostnameStr UTF8String];
	UInt32 usernameLength = (UInt32)[usernameStr length];
	const char* username=[usernameStr UTF8String];
	
	return SecKeychainFindInternetPassword(NULL, 
										   hostnameLength, 
										   hostname, 
										   0, 
										   NULL,
										   usernameLength, 
										   username, 
										   strlen(""), 
										   "", 
										   hostport,
										   kSecProtocolTypeSSH,
										   kSecAuthenticationTypeDefault,
										   passwordLength,
										   passwordData,
										   itemRef);
	
}


//! Cocoa wrapper for SecKeychainItemModifyAttributesAndData 
+ (OSStatus) changePasswordKeychain:(SecKeychainItemRef)itemRef password:(NSString*) newPassword 
{
	if ( !newPassword )
		newPassword=@"";
		
	void* cnewpassword=(void*)[newPassword UTF8String]; 
		UInt32 passwordLength = (UInt32)strlen(cnewpassword);
	
	
	return SecKeychainItemModifyAttributesAndData(itemRef, 
												  NULL, passwordLength, cnewpassword);
}


@end

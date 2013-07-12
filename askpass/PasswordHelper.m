//
//  PasswordHelper.m
//  sshproxy
//
//  Created by Brant Young on 21/6/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "PasswordHelper.h"
#import "SSHHelper.h"
#import "EMKeychain.h"

@implementation PasswordHelper


#pragma mark - Password Helper

//! Simply looks for the keychain entry corresponding to a username and hostname and returns it. Returns nil if the password is not found
+ (NSString *)passwordForHost:(NSString *)hostName port:(int) hostPort user:(NSString *) userName
{
	if ( hostName == nil || userName == nil ){
		return nil;
	}
	
	EMInternetKeychainItem *keychainItem = [EMInternetKeychainItem internetKeychainItemForServer:hostName withUsername:userName path:nil port:hostPort protocol:kSecProtocolTypeSSH];
    
    return keychainItem ? keychainItem.password : @"";
}

+ (NSString *)passwordForServer:(NSDictionary *)server
{
    NSString* remoteHost = [SSHHelper hostFromServer:server];
    NSString* loginName = [SSHHelper userFromServer:server];
    int remotePort = [SSHHelper portFromServer:server];
    
    return [self passwordForHost:remoteHost port:remotePort user:loginName];
}


/*! Set the password into the keychain for a specific user and host. If the username/hostname combo already has an entry in the keychain then change it. If not then add a new entry */
+ (BOOL)setPassword:(NSString*)newPassword forHost:(NSString*)hostName port:(int) hostPort user:(NSString*) userName
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
+ (BOOL)setPassword:(NSString *)newPassword forServer:(NSDictionary *)server
{
    NSString* remoteHost = [SSHHelper hostFromServer:server];
    NSString* loginName = [SSHHelper userFromServer:server];
    int remotePort = [SSHHelper portFromServer:server];
    
    return [self setPassword:newPassword forHost:remoteHost port:remotePort user:loginName];
}

+ (BOOL)deletePasswordForHost:(NSString*)hostName port:(int) hostPort user:(NSString*) userName
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

#pragma mark - Passphrase Helper

//! Simply looks for the keychain entry corresponding to a username and hostname and returns it. Returns nil if the password is not found
+ (NSString *)passphraseForServer:(NSDictionary *)server
{
	if ( !server ){
		return nil;
	}
	
	EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"com.codinnstudio.sshproxy.privatekey" withUsername:[SSHHelper importedPrivateKeyNameFromServer:server]];
    
    return keychainItem ? keychainItem.password : @"";
}


/*! Set the password into the keychain for a specific user and host. If the username/hostname combo already has an entry in the keychain then change it. If not then add a new entry */
+ (BOOL)setPassphrase:(NSString *)newPassphrase forServer:(NSDictionary *)server
{
	if ( !server ) {
		return NO;
	}
	
	// Look for a password in the keychain
    EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"com.codinnstudio.sshproxy.privatekey" withUsername:[SSHHelper importedPrivateKeyNameFromServer:server]];
    
    if (!keychainItem) {
        keychainItem = [EMGenericKeychainItem addGenericKeychainItemForService:@"com.codinnstudio.sshproxy.privatekey" withUsername:[SSHHelper importedPrivateKeyNameFromServer:server] password:newPassphrase];
        return NO;
    }
    
    keychainItem.password = newPassphrase;
    return YES;
}

+ (BOOL)deletePassphraseForServer:(NSDictionary *)server
{
	if ( !server ) {
		return NO;
	}
    
	// Look for a password in the keychain
    EMGenericKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:@"com.codinnstudio.sshproxy.privatekey" withUsername:[SSHHelper importedPrivateKeyNameFromServer:server]];
    
    if (!keychainItem) {
        return NO;
    }
    
    [EMGenericKeychainItem removeKeychainItem:keychainItem];
    return YES;
}

#pragma mark Prompt Password

+ (NSArray *)promptPasswordForServer:(NSDictionary *)server
{
    NSString* remoteHost = [SSHHelper hostFromServer:server];
    int remotePort = [SSHHelper portFromServer:server];
    NSString* loginUser = [SSHHelper userFromServer:server];
    
    BOOL isPublicKeyMode = [SSHHelper authMethodFromServer:server] == OW_AUTH_METHOD_PUBLICKEY;
    
	CFUserNotificationRef passwordDialog;
	SInt32 error;
	CFOptionFlags responseFlags;
	int button;
	CFStringRef passwordRef;
    
	NSMutableArray *returnArray = [NSMutableArray arrayWithObjects:@"PasswordString",[NSNumber numberWithInt:0],[NSNumber numberWithInt:1],nil];
    
    NSString* hostString = [NSString stringWithFormat:@"%@:%d", remoteHost, remotePort];
    
    NSString *passwordMessageString = nil;
    NSString *remeberCheckBoxTitle = nil;
    if (isPublicKeyMode) {
        passwordMessageString = [NSString stringWithFormat:@"Enter the passphrase for private key imported from “%@”.", [SSHHelper privateKeyPathFromServer:server]];
        remeberCheckBoxTitle = @"Remember this passphrase in my keychain";
    } else {
        passwordMessageString = [NSString stringWithFormat:@"Enter the password for user “%@”.", loginUser];
        remeberCheckBoxTitle = @"Remember this password in my keychain";
    }
    
    NSString* headerString = [NSString stringWithFormat:@"SSH Proxy connecting to the SSH server “%@”.", hostString];
    
    NSURL *iconURL = [[NSBundle mainBundle] URLForResource:@"logo" withExtension:@"icns" subdirectory:@""];
    
	NSDictionary *panelDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               iconURL, kCFUserNotificationIconURLKey,
                               headerString,kCFUserNotificationAlertHeaderKey,
                               passwordMessageString,kCFUserNotificationAlertMessageKey,
							   @"",kCFUserNotificationTextFieldTitlesKey,
							   @"Cancel",kCFUserNotificationAlternateButtonTitleKey,
                               remeberCheckBoxTitle,
                               kCFUserNotificationCheckBoxTitlesKey,
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
        [returnArray replaceObjectAtIndex:1 withObject:@(error)];
		return returnArray;
	}
    
	error = CFUserNotificationReceiveResponse(passwordDialog,
											  0,
											  &responseFlags);
    
	if (error){
		CFRelease(passwordDialog);
        [returnArray replaceObjectAtIndex:1 withObject:@(error)];
		return returnArray;
	}
    
    
	button = responseFlags & 0x3;
	if (button == kCFUserNotificationAlternateResponse) {
		CFRelease(passwordDialog);
        [returnArray replaceObjectAtIndex:1 withObject:@1];
		return returnArray;
	}
    
	if ( responseFlags & CFUserNotificationCheckBoxChecked(0) ) {
        [returnArray replaceObjectAtIndex:2 withObject:@0];
	}
	passwordRef = CFUserNotificationGetResponseValue(passwordDialog,
													 kCFUserNotificationTextFieldValuesKey,
													 0);
    
    
    [returnArray replaceObjectAtIndex:0 withObject:(__bridge NSString*)passwordRef];
	CFRelease(passwordDialog); // Note that this will release the passwordRef as well
	return returnArray;
}


@end

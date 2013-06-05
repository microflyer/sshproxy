//
//  main.m
//  askpass
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#include <Cocoa/Cocoa.h>
#import "PasswordHelper.h"

/*! The ASKPASS program for ssh (and for rsync via ssh).
 
 When ssh (or rsync) needs a response from the user it asks this program instead (provided that ssh or rsync have been started with the appropriate environment variables set).
 
 Sometimes ssh will ask for a password, but if a connection is being established to a server for the first time it will ask whether the user wants to add the host to the list of known hosts (in that case the required response is "yes"). This program figures out what the correct response is and supplies it.
 
 If a password for the user/hostname combination is not available this program will prompt the user for a password.
 
 */

int main() {
	// Get basic information from environment variables that were set along with the NSTask itself. We need this info in order to get the correct password from the security keychain
	NSDictionary *dict = [[NSProcessInfo processInfo] environment];
	NSString *loginname = [dict valueForKey:@"SSHPROXY_LOGIN_NAME"];
	NSString *remotehost = [dict valueForKey:@"SSHPROXY_REMOTE_HOST"];
    int hostport = [[dict valueForKey:@"SSHPROXY_REMOTE_PORT"] intValue];
    NSString* userhome = [dict valueForKey:@"SSHPROXY_USER_HOME"];
    
	// The arguments array should contain three elements. The second element is a string which we can use to determine the context in which this program was invoked. This string is either a message prompting for a yes/no or a message prompting for a password. We check it and supply the right response.
	NSArray *argumentsArray = [[NSProcessInfo processInfo] arguments];
	if ( [argumentsArray count] >= 2 ){
		NSRange yesnoRange = [[argumentsArray objectAtIndex:1] rangeOfString:[NSString stringWithFormat:@"(yes/no)"]];
		
		// If the string yes/no was found in the arguments array then we need to return a YES instead of password
		if ( yesnoRange.location != NSNotFound ){
			printf("%s","YES");
			return 0;
		}
	}
	
	if ( loginname!=nil && remotehost!=nil ){
        NSString* lockFile= [userhome stringByAppendingPathComponent:@".sshproxy_askpass_lock"];
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:lockFile];
        
		// First try to get the password from the keychain
		NSString *pStr = [PasswordHelper passwordForHost:remotehost port:hostport user:loginname];
		if ( pStr==nil || fileExists ){
			// No password was found in the keychain so we should prompt the user for it.
			NSArray *promptArray = [PasswordHelper promptForPassword:remotehost port:hostport user:loginname];
			NSInteger returnCode = [[promptArray objectAtIndex:1] intValue];
			if ( returnCode == 0 ){ // Found a valid password entry
				
                // Set the password in the keychain if the user requested this.
				if ( [[promptArray objectAtIndex:2] intValue]==0 ){
					[PasswordHelper setPassword:[promptArray objectAtIndex:0] forHost:remotehost port:hostport user:loginname];
				}
				
				void *pword=(void*)[[promptArray objectAtIndex:0] UTF8String];
				printf("%s",(char*)pword);
				return 0;
			} else if ( returnCode == 1 ){ // User cancelled so we'll just abort
				// We return a non zero exit code here which should cause ssh to abort
				return 1;
			}
		}
        // create lock file !
        if (!fileExists) {
            // [[NSFileManager defaultManager] createFileAtPath:lockFile contents:nil attributes: nil];
            // use plain c to avoid create unprivileged cache file
            FILE *fh = fopen([lockFile UTF8String], "w");
            fclose(fh);
        }
        
		void *pword=(void*)[pStr UTF8String];
		printf("%s",(char*)pword);
		return 0;
	}
	
	// If we get to here something has gone wrong. Just return 1 to indicate failure
	return 1;
}

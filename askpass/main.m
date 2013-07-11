//
//  main.m
//  askpass
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PasswordHelper.h"
#import "SSHHelper.h"

/*! The ASKPASS program for SSH Proxy.
 
 When ssh (or rsync) needs a response from the user it asks this program instead (provided that ssh or rsync have been started with the appropriate environment variables set).
 
 Sometimes ssh will ask for a password, but if a connection is being established to a server for the first time it will ask whether the user wants to add the host to the list of known hosts (in that case the required response is "yes"). This program figures out what the correct response is and supplies it.
 */

int main() {
    @autoreleasepool
    {
        // Get basic information from environment variables that were set along with the NSTask itself. We need this info in order to get the correct password from the security keychain
        NSDictionary *dict = [[NSProcessInfo processInfo] environment];
        NSString* userHome = [dict valueForKey:@"SSHPROXY_USER_HOME"];
        
        NSString* encryptedServerInfo = [dict valueForKey:@"SSHPROXY_SERVER_INFO"];
        NSDictionary *server = [SSHHelper decryptServerInfo:encryptedServerInfo forDir:userHome];
                
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
        
        if ( !server ) {
            return 1;
        }
        
        NSString* lockFile= [userHome stringByAppendingPathComponent:OW_SSHPROXY_ASKPASS_LOCK];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:lockFile];
        
        BOOL isPublicKeyMode = [SSHHelper authMethodFromServer:server]==OW_AUTH_METHOD_PUBLICKEY;
        
        // First try to get the password from the keychain
        NSString *password = nil;
        if (isPublicKeyMode) {
            password = [PasswordHelper passphraseForServer:server];
        } else {
            password = [PasswordHelper passwordForServer:server];
        }
        
        // First try to get the password from the keychain
        if ( [password isEqual:@""] || fileExists ) {
            // No password was found in the keychain or password is incorrect
            // so we should prompt the user for it.
            
            NSArray *promptArray = [PasswordHelper promptPasswordForServer:server];
            NSInteger returnCode = [[promptArray objectAtIndex:1] intValue];
            if ( returnCode == 0 ){
                // Found a valid password entry
                password = [promptArray objectAtIndex:0];
                
                // Set the password in the keychain if the user requested this.
                if ( [[promptArray objectAtIndex:2] intValue]==0 ){
                    if (isPublicKeyMode) {
                        [PasswordHelper setPassphrase:password forServer:server];
                    } else {
                        [PasswordHelper setPassword:password forServer:server];
                    }
                    
                    void *pword=(void*)[password UTF8String];
                    printf("%s",(char*)pword);
                    return 0;
                } else if ( returnCode == 1 ) {
                    // User cancelled so we'll just abort
                    // We return a non zero exit code here which should cause ssh to abort
                    return 1;
                }
            }
        }
        
        // create lock file !
        if (!fileExists) {
            // [[NSFileManager defaultManager] createFileAtPath:lockFile contents:nil attributes: nil];
            // use plain c to avoid create unprivileged cache file
            FILE *fh = fopen([lockFile UTF8String], "w");
            fclose(fh);
        }
        
        void *pword=(void*)[password UTF8String];
        printf("%s",(char*)pword);
        return 0;
    } // @autoreleasepool
}

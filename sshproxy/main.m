#import <Foundation/Foundation.h>



void doTaskAndCapture(void);

void doTaskAndCapture()

{
    
    @try
    
    {
        
        NSDictionary *env = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"spig", @"CHARM_SSH_LOGIN",
                             @"codinn.com", @"CHARM_SSH_REMOTE_HOST",
                             @"22", @"CHARM_SSH_REMOTE_PORT",
                             @"7072", @"CHARM_SSH_LOCAL_PORT",
                             @":9999", @"DISPLAY",
                             @"/Users/brantyoung/Library/Developer/Xcode/DerivedData/SSH_Proxy-bbxzfribgdyduhffhaoswciuuuvz/Build/Products/Debug/askpass", @"SSH_ASKPASS",
                             @"1",@"INTERACTION",
                             nil];

        
        
        // Set up the process
        
        NSTask *t = [[NSTask alloc] init];
        NSString* userHome = NSHomeDirectory();
        NSString* knownHostFile= [userHome stringByAppendingPathComponent:@".charmssh_known_hosts"];
        NSString* identityFile= [userHome stringByAppendingPathComponent:@".charmssh_ssh_identity"];
        
        [t setLaunchPath:@"/usr/bin/ssh"];
        
        [t setArguments:[NSArray arrayWithObjects:
                         [NSString stringWithFormat:@"-oUserKnownHostsFile=\"%@\"", knownHostFile],
                         [NSString stringWithFormat:@"-oIdentityFile=\"%@\"", identityFile],
                         @"-oStrictHostKeyChecking=no", @"-CND", @"7072", @"spig@codinn.com", nil]];
        
        [t setEnvironment:env];
        
        // Set the pipe to the standard output and error to get the results of the command
        
        NSPipe *p = [[NSPipe alloc] init];
        
        [t setStandardOutput:p];
        
        [t setStandardError:p];
        
        // Launch (forks) the process
        
        [t launch]; // raises an exception if something went wrong
        
        // Prepare to read
        
//        NSFileHandle *readHandle = [p fileHandleForReading];
//        
//        NSData *inData = nil;
//        
//        NSMutableData *totalData = [[NSMutableData alloc] init];
//        
//        while ((inData = [readHandle availableData]) &&
//               
//               [inData length]) {
//            
//            [totalData appendData:inData];
//            
//        }
//        NSData* data = [[p fileHandleForReading] readDataToEndOfFile];
        
        // Polls the runloop until its finished
        
        [t waitUntilExit];
        
        NSString *output = [[NSString alloc]
                             initWithData:[[p fileHandleForReading] readDataToEndOfFile]
                            encoding:NSUTF8StringEncoding];
        
        NSLog(@"Terminationstatus: %d", [t terminationStatus]);
        
        NSLog(@"Data recovered: %@", output);
        
    }
    
    @catch (NSException *e)
    
    {
        
        NSLog(@"Expection occurred %@", [e reason]);
        
    }
    
}



int main(int argc, char *argv[]) {
    return NSApplicationMain(argc, (const char **)argv);
}

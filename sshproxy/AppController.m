//
//  AppController.m
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//
#import "AppController.h"
#import "GeneralPreferencesViewController.h"
#import "MASPreferencesWindowController.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation AppController

-(id)init{
    self = [super init];
    if (self){
        taskOutput = [[NSString alloc] init];
    }
    return self;
}


- (void) awakeFromNib{
    [NSApp setMainMenu:mainMenu];
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    offStatusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"red-hard-drive-network_64x64" ofType:@"png"]];
    [offStatusImage setSize:NSMakeSize(20,20)];
    
    onStatusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"green-hard-drive-network_64x64" ofType:@"png"]];
    [onStatusImage setSize:NSMakeSize(20,20)];
    
    inStatusImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"yellow-hard-drive-network_64x64" ofType:@"png"]];
    [inStatusImage setSize:NSMakeSize(20,20)];
    
    statusHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"red-hard-drive-network_64x64" ofType:@"png"]];
    [statusHighlightImage setSize:NSMakeSize(20,20)];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:offStatusImage];
//    [statusItem setAlternateImage:statusHighlightImage];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"SSH Proxy"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    BOOL disableAutoconnect = [[NSUserDefaults standardUserDefaults] boolForKey:@"disable_autoconnect"];
    BOOL autoLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"auto_launch"];
    
    if (! disableAutoconnect) {
        [self performSelector: @selector(turnOnProxy:) withObject:self afterDelay: 0.0];
    }
    
    if (autoLaunch) {
        // reenable
        SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.codinnstudio.sshproxyhelper", YES);
    } else {
        SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.codinnstudio.sshproxyhelper", NO);
    }
}

- (void) dealloc {
    //Releases the 2 images we loaded into memory
//    [statusImage release];
//    [statusHighlightImage release];
//    [super dealloc];
}

-(IBAction)turnOnProxy:(id)sender{
    proxyStatus = SSHPROXY_ON;
    
    [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 0.0];
}

-(IBAction)_turnOnProxy:(id)sender{
    NSString* remoteHost = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"remote_host"];
    // open preferences window if remoteHost is empty
    if (!remoteHost) {
        [self performSelector: @selector(openPreferences:) withObject:self afterDelay: 0.0];
        return;
    }
    
    // get perferences
    //    NSString* remoteHost = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"remote_host"];
    if (!remoteHost) {
        remoteHost = @"";
    }
    
    NSString* loginName = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"login_name"];
    if (!loginName) {
        loginName = @"";
    }
    
    int remotePort = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"remote_port"];
    if (remotePort<=0 || remotePort>65535) {
        remotePort = 22;
    }
    
    int localPort = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
    if (localPort<=0 || localPort>65535) {
        localPort = 7070;
    }
    
    NSString* connectingString = [NSString stringWithFormat:@"Proxy: Connecting to \"%@@%@:%d\" ...", loginName, remoteHost, remotePort];
    [statusItem setImage:inStatusImage];
    [statusMenuItem setTitle:connectingString];
    
    // TODO: CATCH TASK EXCEPTION
    
    [turnOnMenuItem setHidden:YES];
    [turnOnMenuItem setEnabled:NO];
    
    [turnOffMenuItem setHidden:NO];
    [turnOffMenuItem setEnabled:YES];
    
    if (task) {
        // task already running, do noting
        return;
    }
    
    task = [[NSTask alloc] init];
    NSString* userHome = NSHomeDirectory();
    NSString* knownHostFile= [userHome stringByAppendingPathComponent:@".sshproxy_known_hosts"];
    NSString* identityFile= [userHome stringByAppendingPathComponent:@".sshproxy_identity"];
//    NSString* configFile= [userHome stringByAppendingPathComponent:@".sshproxy_config"];
    
    // Get the path of our Askpass program, which we've included as part of the main application bundle
    NSString *askPassPath = [NSBundle pathForResource:@"SSH Proxy - Ask Password" ofType:@""
                                          inDirectory:[[NSBundle mainBundle] bundlePath]];
    
    // This creates a dictionary of environment variables (keys) and their values (objects) to be set in the environment where the task will be run. This environment dictionary will then be accessible to our Askpass program.
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                loginName, @"SSHPROXY_LOGIN_NAME",
                                remoteHost, @"SSHPROXY_REMOTE_HOST",
                                [NSString stringWithFormat:@"%d", remotePort], @"SSHPROXY_REMOTE_PORT",
//                                [NSString stringWithFormat:@"%d", localPort], @"SSHPROXY_LOCAL_PORT",
                                @":9999", @"DISPLAY",
                                askPassPath, @"SSH_ASKPASS",
                                userHome, @"SSHPROXY_USER_HOME",
                                @"1",@"INTERACTION",
                                nil];
    
    BOOL enableCompression = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_compression"];
    BOOL shareSocks = [[NSUserDefaults standardUserDefaults] boolForKey:@"share_socks"];
    
    NSMutableString* advancedOptions = [NSMutableString stringWithString:@"-"];
    if (shareSocks) {
        [advancedOptions appendString:@"g"];
    }
    if (enableCompression) {
        [advancedOptions appendString:@"C"];
    }
    [advancedOptions appendString:@"ND"];
    
    
//    NSLog(@"Environment dict %@",env);
    
    [task setEnvironment:env];
    [task setArguments:[NSArray arrayWithObjects:
                        [NSString stringWithFormat:@"-oUserKnownHostsFile=\"%@\"", knownHostFile],
                        [NSString stringWithFormat:@"-oGlobalKnownHostsFile=\"%@\"", knownHostFile],
                        [NSString stringWithFormat:@"-oIdentityFile=\"%@\"", identityFile],
                        // TODO:
//                        [NSString stringWithFormat:@"-F \"%@\"", configFile],
                        @"-oIdentitiesOnly=yes",
                        @"-oPubkeyAuthentication=no",
                        @"-T", @"-2", @"-a",
                        @"-oConnectTimeout=8", @"-oConnectionAttempts=3",
                        @"-oServerAliveInterval=8", @"-oServerAliveCountMax=1",
                        @"-oStrictHostKeyChecking=no", @"-oExitOnForwardFailure=yes",
                        @"-oLogLevel=DEBUG",
                        @"-oPreferredAuthentications=password",
                        advancedOptions, [NSString stringWithFormat:@"%d", localPort],
                        [NSString stringWithFormat:@"%@@%@", loginName, remoteHost],
                        @"-p", [NSString stringWithFormat:@"%d", remotePort],
                        nil]];
    
    [task setLaunchPath:@"/usr/bin/ssh"];
    
    // Setup the pipes on the task
    pipe = [[NSPipe alloc] init];
    //        errorPipe = [[NSPipe alloc] init];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    // It's important that we set the standard input to null here. This is sometimes required in order to get SSH to use our Askpass program rather then prompt the user interactively.
    [task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    
    // clear taskOutput buffer
    taskOutput = [[NSString alloc] init];
    
    NSFileHandle *fh = [pipe fileHandleForReading];
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [nc addObserver:self
           selector:@selector(dataReady:) name:NSFileHandleReadCompletionNotification
             object:fh];
    [nc addObserver:self
           selector:@selector(taskTerminated:) name:NSTaskDidTerminateNotification
             object:task];
    
    // delete askpass lock file
    NSString* lockFile= [userHome stringByAppendingPathComponent:@".sshproxy_askpass_lock"];
    [[NSFileManager defaultManager] removeItemAtPath:lockFile error:nil];
    
    [task launch];
    
    //        [outputView setString:@""];
    [fh readInBackgroundAndNotify];
}

- (void)set2connected {
    [statusItem setImage:onStatusImage];
    [statusMenuItem setTitle:@"Proxy: On"];
    proxyStatus = SSHPROXY_CONNECTED;
}

- (void)dataReady:(NSNotification *)n
{
    NSData *d;
    d = [[n userInfo] valueForKey:NSFileHandleNotificationDataItem];
//    NSLog(@"dataReady:% ld bytes", [d length]);
    if ([d length]) {
        NSString *s = [[NSString alloc] initWithData:d
                                            encoding:NSUTF8StringEncoding];
        
        taskOutput = [taskOutput stringByAppendingString:s];
    }
    // If the task is running, start reading again
    if (task) {
        if ( ([taskOutput rangeOfString:@"Authenticated to"].location != NSNotFound) ||
            ([taskOutput rangeOfString:@"Authentication succeeded"].location != NSNotFound) ){
            [self set2connected];
        }
        [[pipe fileHandleForReading] readInBackgroundAndNotify];
    } else {
        if ([taskOutput rangeOfString:@"bind: Address already in use"].location != NSNotFound) {
            [statusMenuItem setTitle:@"Proxy: Off - port already in use"];
            return;
        } else if ([taskOutput rangeOfString:@"Permission denied (publickey,password)"].location != NSNotFound) {
            [statusMenuItem setTitle:@"Proxy: Off - incorrect password"];
            return;
        } else if ([taskOutput rangeOfString:@"ssh: Could not resolve hostname"].location != NSNotFound) {
            if (proxyStatus==SSHPROXY_CONNECTED) {
                [statusItem setImage:inStatusImage];
                [statusMenuItem setTitle:@"Proxy: Reconnecting - could not resolve hostname"];
                [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 3.0];
            } else {
                [statusMenuItem setTitle:@"Proxy: Off - could not resolve hostname"];
            }
        } else if ([taskOutput rangeOfString:@"Connection refused"].location != NSNotFound) {
            if (proxyStatus==SSHPROXY_CONNECTED) {
                [statusItem setImage:inStatusImage];
                [statusMenuItem setTitle:@"Proxy: Reconnecting - connection refused"];
                [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 3.0];
            } else {
                [statusMenuItem setTitle:@"Proxy: Off - connection refused"];
            }
        } else if ([taskOutput rangeOfString:@"Timeout,"].location != NSNotFound) {
            if (proxyStatus==SSHPROXY_CONNECTED) {
                [statusItem setImage:inStatusImage];
                [statusMenuItem setTitle:@"Proxy: Reconnecting - timeout, server not responding"];
                [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 3.0];
            } else {
                [statusMenuItem setTitle:@"Proxy: Off - timeout, server not responding"];
            }
        } else if ([taskOutput rangeOfString:@"timed out"].location != NSNotFound) {
            if (proxyStatus==SSHPROXY_CONNECTED) {
                [statusItem setImage:inStatusImage];
                [statusMenuItem setTitle:@"Proxy: Reconnecting - connection timed out"];
                [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 3.0];
            } else {
                [statusMenuItem setTitle:@"Proxy: Off - connection timed out"];
            }
        } else {
            if (proxyStatus==SSHPROXY_CONNECTED) {
                [statusItem setImage:inStatusImage];
                [statusMenuItem setTitle:@"Proxy: Reconnecting - unknown error"];
                [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 3.0];
            } else {
                [statusMenuItem setTitle:@"Proxy: Off"];
            }
        }
        
        // clear taskOutput buffer
        taskOutput = [[NSString alloc] init];
    }
}
// When the process is done, we should do some cleanup:
- (void)taskTerminated:(NSNotification *)note {
    [statusItem setImage:offStatusImage];
//    [statusMenuItem setTitle:@"Proxy: Off"];
//    NSLog([NSString stringWithFormat:@"taskTerminated: %@", taskOutput]);
//    NSLog([NSString stringWithFormat:@"taskTerminated: %@", taskOutput]);
    task = nil;
    
    // ensure
    [turnOffMenuItem setHidden:YES];
    [turnOffMenuItem setEnabled:NO];
    
    [turnOnMenuItem setHidden:NO];
    [turnOnMenuItem setEnabled:YES];
    
    // show and enable turn on menu
//    [turnOnMenuItem setHidden:NO];
//    [turnOnMenuItem setEnabled:YES];
}


-(IBAction)turnOffProxy:(id)sender{
    proxyStatus = SSHPROXY_OFF;
    
    // clear taskOutput buffer
    taskOutput = [[NSString alloc] init];
    
    // TODO: CATCH TASK EXCEPTION
    
    [turnOffMenuItem setHidden:YES];
    [turnOffMenuItem setEnabled:NO];
    
    [turnOnMenuItem setHidden:NO];
    [turnOnMenuItem setEnabled:YES];
    
    if (!task) {
        // dead task , do noting
        return;
    }
    
    [task interrupt];
}


- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[GeneralPreferencesViewController alloc] init];
//        NSViewController *advancedViewController = [[AdvancedPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"SSH Proxy Preferences", @"SSH Proxy Preferences");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
        
        [[_preferencesWindowController window] setReleasedWhenClosed: NO];
    }
    return _preferencesWindowController;
}

-(IBAction)openPreferences:(id)sender {
    if(_preferencesWindowController) {
       [_preferencesWindowController close];
        _preferencesWindowController = nil;
    }
    
    [NSApp activateIgnoringOtherApps:YES];
//    [[self.preferencesWindowController window] makeKeyAndOrderFront:nil];
//    [[self.preferencesWindowController window] setLevel:NSFloatingWindowLevel];
    [[self.preferencesWindowController window] setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [[self.preferencesWindowController window] center];
    [self.preferencesWindowController showWindow:nil];
}

-(IBAction)openAboutWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    
    [aboutWindow makeKeyAndOrderFront:nil];
    [aboutWindow setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [aboutWindow center];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [task interrupt];
    return NSTerminateNow;
}

@end

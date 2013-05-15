//
//  AppController.m
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//
#import "AppController.h"
#import "GeneralPreferencesViewController.h"
#import "ServersPreferencesViewController.h"
#import "MASPreferencesWindowController.h"
#import "SSHHelper.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation AppController

-(id)init
{
    self = [super init];
    if (self){
        taskOutput = [[NSString alloc] init];
    }
    return self;
}


- (void) awakeFromNib
{
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
    
    //Tells the NSStatusItem what action to active
    [statusItem setAction:@selector(statusItemClicked)];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"SSH Proxy"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}

- (void)statusItemClicked
{
    NSMenu* menu = [statusMenu copy];
    menu.minimumWidth = 256.0;
    
    NSArray* servers = [[NSUserDefaults standardUserDefaults] arrayForKey:@"servers"];
    NSInteger activatedServerIndex = [SSHHelper getActivatedServerIndex];
    
    if (servers && servers.count>0) {
//        [menu insertItemWithTitle:@"Servers:" action:nil keyEquivalent:@"" atIndex:4];
        
        int i = 0;
        for (NSDictionary* server in servers) {
            NSMenuItem* item = [NSMenuItem alloc];
            item.title = [NSString stringWithFormat:@" %@@%@", (NSString *)[server valueForKey:@"login_name"], (NSString *)[server valueForKey:@"remote_host"]];
            item.action = @selector(switchServer:);
            item.indentationLevel = 1;
            
            item.representedObject = [NSNumber numberWithInt:i];
            
            if (i==activatedServerIndex) {
                [item setState:NSOnState];
            }
            
            [menu insertItem:item atIndex:4+i];
            i++;
        }
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:4+i];
    }
    
    [statusItem popUpStatusItemMenu:menu];
}


- (void)switchServer:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    
    int index = [(NSNumber*)menuItem.representedObject intValue];
    [SSHHelper setActivatedServer:index];
    
    [self performSelector: @selector(turnOffProxy:) withObject:self afterDelay: 0.0];
    [task waitUntilExit];
    [self performSelector: @selector(turnOnProxy:) withObject:self afterDelay: 0.0];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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

- (IBAction)turnOnProxy:(id)sender
{
    proxyStatus = SSHPROXY_ON;
    
    [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 0.0];
}

- (IBAction)_turnOnProxy:(id)sender
{
    NSDictionary* server = [SSHHelper getActivatedServer];
    
    // open preferences window if remoteHost is empty
    if (!server) {
        [self openServersPreferences];
        return;
    }
    
    NSString* remoteHost = (NSString *)[server valueForKey:@"remote_host"];
    NSString* loginName = (NSString *)[server valueForKey:@"login_name"];
    int remotePort = [(NSNumber*)[server valueForKey:@"remote_port"] intValue];
    int localPort = [(NSNumber*)[server valueForKey:@"local_port"] intValue];
    BOOL enableCompression = [(NSNumber*)[server valueForKey:@"enable_compression"] boolValue];
    BOOL shareSocks = [(NSNumber*)[server valueForKey:@"share_socks"] boolValue];
    
    // get perferences
    if (!remoteHost) {
        remoteHost = @"";
    }
    
    
    if (!loginName) {
        loginName = @"";
    }
    
    if (remotePort<=0 || remotePort>65535) {
        remotePort = 22;
    }
    
    if (localPort<=0 || localPort>65535) {
        localPort = 7070;
    }
    
    NSString* connectingString = [NSString stringWithFormat:@"Proxy: Connecting ..."];
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
    
    // Get the path of our Askpass program, which we've included as part of the main application bundle
    NSString *askPassPath = [NSBundle pathForResource:@"SSH Proxy - Ask Password" ofType:@""
                                          inDirectory:[[NSBundle mainBundle] bundlePath]];
    
    // This creates a dictionary of environment variables (keys) and their values (objects) to be set in the environment where the task will be run. This environment dictionary will then be accessible to our Askpass program.
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                loginName, @"SSHPROXY_LOGIN_NAME",
                                remoteHost, @"SSHPROXY_REMOTE_HOST",
                                [NSString stringWithFormat:@"%d", remotePort], @"SSHPROXY_REMOTE_PORT",
                                @":9999", @"DISPLAY",
                                askPassPath, @"SSH_ASKPASS",
                                userHome, @"SSHPROXY_USER_HOME",
                                @"1",@"INTERACTION",
                                nil];
    [env addEntriesFromDictionary:[SSHHelper getProxyCommandEnv]];
    
    NSMutableString* advancedOptions = [NSMutableString stringWithString:@"-"];
    if (shareSocks) {
        [advancedOptions appendString:@"g"];
    }
    if (enableCompression) {
        [advancedOptions appendString:@"C"];
    }
    [advancedOptions appendString:@"ND"];
    
    //    DLog(@"Environment dict %@",env);
    
    NSMutableArray *arguments = [SSHHelper getConnectArgs];
    NSString *proxyCommandStr = [SSHHelper getProxyCommandStr];
    
    if (proxyCommandStr) {
        [arguments addObject:proxyCommandStr];
    }
    
    [arguments addObjectsFromArray:@[
                                     advancedOptions,
                                     [NSString stringWithFormat:@"%d", localPort],
                                     [NSString stringWithFormat:@"%@@%@", loginName, remoteHost],
                                     @"-p",
                                     [NSString stringWithFormat:@"%d", remotePort]
                                ]
     ];
    
    [task setEnvironment:env];
    [task setArguments:arguments];
    
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
    
    [fh readInBackgroundAndNotify];
}

- (void)set2connected {
    [statusItem setImage:onStatusImage];
    [statusMenuItem setTitle:@"Proxy: On"];
    proxyStatus = SSHPROXY_CONNECTED;
}

- (void)reconnectIfNeed:(NSString*) state
{
    if (proxyStatus==SSHPROXY_CONNECTED) {
        [statusItem setImage:inStatusImage];
        [statusMenuItem setTitle:[NSString stringWithFormat:@"Proxy: Reconnecting - %@", state]];
        [self performSelector: @selector(_turnOnProxy:) withObject:self afterDelay: 3.0];
    } else {
        [statusMenuItem setTitle:[NSString stringWithFormat:@"Proxy: Off - %@", state]];
    }
}

- (void)dataReady:(NSNotification *)n
{
    NSData *d;
    d = [[n userInfo] valueForKey:NSFileHandleNotificationDataItem];
    //    DLog(@"dataReady:% ld bytes", [d length]);
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
        } else {
            NSArray* errors = @[
                                @[@"ssh: Could not resolve hostname"   , @"could not resolve hostname"],
                                @[@"Connection refused"                , @"connection refused"],
                                @[@"Timeout,"                          , @"timeout, server not responding"],
                                @[@"timed out"                         , @"connection timed out"],
                                @[@"Write failed: Broken pipe"         , @"disconnected from  remote proxy server"],
                                @[@"Connection closed by remote host"  , @"failed to connect remote proxy server"],
                                @[@"unknown error"                     , @"unknown error"], // TODO: has bug when manually Turn Off
                                ];
            for (NSArray* error in errors) {
                if ( ([taskOutput rangeOfString:error[0]].location != NSNotFound) || [error[0]isEqual:@"unknown error"]) {
                    [self reconnectIfNeed:error[1]];
                    break;
                }
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
    DLog(@"taskTerminated: %@", taskOutput);
    task = nil;
    
    // ensure
    [turnOffMenuItem setHidden:YES];
    [turnOffMenuItem setEnabled:NO];
    
    // show and enable turn on menu
    [turnOnMenuItem setHidden:NO];
    [turnOnMenuItem setEnabled:YES];
}


-(IBAction)turnOffProxy:(id)sender{
    proxyStatus = SSHPROXY_OFF;
    
    DLog(@"Turn off proxy: %@", taskOutput);
    
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
        NSViewController *serversViewController = [[ServersPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, serversViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"SSH Proxy Preferences", @"SSH Proxy Preferences");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
        
        [[_preferencesWindowController window] setReleasedWhenClosed: NO];
    }
    return _preferencesWindowController;
}

- (IBAction)openPreferences:(id)sender
{
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


- (void)openServersPreferences
{
    [self performSelector: @selector(openPreferences:) withObject:self afterDelay: 0.0];
    
    [self.preferencesWindowController selectControllerAtIndex:1];
}

- (IBAction)openAboutWindow:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    
    [aboutWindow makeKeyAndOrderFront:nil];
    [aboutWindow setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [aboutWindow center];
}

-(IBAction)openSendFeedback:(id)sender
{
    NSString *encodedSubject = @"subject=SSH Proxy Support";
    NSString *encodedBody = @"body=Hi Yang,";
    NSString *encodedTo = @"yang@yangyubo.com";
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@&%@",
                                  [encodedTo stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [encodedSubject stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                                  [encodedBody stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    DLog(@"%@", encodedURLString);
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

-(IBAction)openMacAppStore:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:
     [NSURL URLWithString:@"macappstore://itunes.apple.com/app/ssh-proxy/id597790822?mt=12"]];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [task interrupt];
    return NSTerminateNow;
}

@end

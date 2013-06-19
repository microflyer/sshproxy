//
//  AppController.m
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//
#import <ServiceManagement/ServiceManagement.h>
#import "AppController.h"
#import "GeneralPreferencesViewController.h"
#import "ServersPreferencesViewController.h"
#import "MASPreferencesWindowController.h"
#import "SSHHelper.h"
#import "PasswordHelper.h"

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
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    offStatusImage = [NSImage imageNamed:@"disconnected"];
    onStatusImage = [NSImage imageNamed:@"connected"];
    inStatusImage = [NSImage imageNamed:@"connecting"];
    
    offStatusInverseImage = [NSImage imageNamed:@"disconnected-inverse"];
    onStatusInverseImage = [NSImage imageNamed:@"connected-inverse"];
    inStatusInverseImage = [NSImage imageNamed:@"connecting-inverse"];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:offStatusImage];
    [statusItem setAlternateImage:offStatusInverseImage];
    
    //Tells the NSStatusItem what action to active
    [statusItem setAction:@selector(statusItemClicked)];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"SSH Proxy"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
    
    // upgrade user preferences from 13.04 to 13.05
    [SSHHelper upgrade1:serverArrayController];
    
    isPasswordCorrect = YES;
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
    
    [self _turnOffProxy];
    [self _turnOnProxy];
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
    
    [self _turnOnProxy];
}

- (void)_turnOnProxy
{
    if (task) {
        // task already running, do noting
        return;
    }
    
    NSDictionary* server = [SSHHelper getActivatedServer];
    
    // open preferences window if remoteHost is empty
    if (!server) {
        [self openServersPreferences];
        return;
    }
    
    NSString* remoteHost = (NSString *)[server valueForKey:@"remote_host"];
    NSString* loginName = (NSString *)[server valueForKey:@"login_name"];
    int remotePort = [(NSNumber*)[server valueForKey:@"remote_port"] intValue];
    NSInteger localPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
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
    
    NSString* userHome = NSHomeDirectory();
    
    // Get the path of our Askpass program, which we've included as part of the main application bundle
    NSString *askPassPath = [NSBundle pathForResource:@"SSH Proxy - Ask Password" ofType:@""
                                          inDirectory:[[NSBundle mainBundle] bundlePath]];
    
    // This creates a dictionary of environment variables (keys) and their values (objects) to be set in the environment where the task will be run. This environment dictionary will then be accessible to our Askpass program.
    
    if (!isPasswordCorrect) {
        isPasswordCorrect = YES;
        
        [PasswordHelper deletePasswordForHost:remoteHost port:remotePort user:loginName];
    }
    
    // First try to get the password from the keychain
    NSString *loginPassword = [PasswordHelper passwordForHost:remoteHost port:remotePort user:loginName];
    if ( !loginPassword ){
        // No password was found in the keychain so we should prompt the user for it.
        NSArray *promptArray = [PasswordHelper promptForPassword:remoteHost port:remotePort user:loginName];
        NSInteger returnCode = [[promptArray objectAtIndex:1] intValue];
        if ( returnCode == 0 ){ // Found a valid password entry
            
            // Set the password in the keychain if the user requested this.
            if ( [[promptArray objectAtIndex:2] intValue]==0 ){
                [PasswordHelper setPassword:[promptArray objectAtIndex:0] forHost:remoteHost port:remotePort user:loginName];
            }
            
            loginPassword = [NSString stringWithUTF8String:[[promptArray objectAtIndex:0]UTF8String]];
        } else if ( returnCode == 1 ){ // User cancelled so we'll just abort
            // We return a non zero exit code here which should cause ssh to abort
            return;
        }
    }
    
    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                loginName, @"SSHPROXY_LOGIN_NAME",
                                remoteHost, @"SSHPROXY_REMOTE_HOST",
                                [NSString stringWithFormat:@"%d", remotePort], @"SSHPROXY_REMOTE_PORT",
                                @":9999", @"DISPLAY",
                                askPassPath, @"SSH_ASKPASS",
                                loginPassword, @"SSH_ASKPASS_PASSWORD",
                                userHome, @"SSHPROXY_USER_HOME",
                                @"1",@"INTERACTION",
                                nil];
    [env addEntriesFromDictionary:[SSHHelper getProxyCommandEnv:server]];
    
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
    NSString *proxyCommandStr = [SSHHelper getProxyCommandStr:server];
    
    if (proxyCommandStr) {
        [arguments addObject:proxyCommandStr];
    }
    
    [arguments addObjectsFromArray:@[
                                     advancedOptions,
                                     [NSString stringWithFormat:@"%ld", (long)localPort],
                                     [NSString stringWithFormat:@"%@@%@", loginName, remoteHost],
                                     @"-p",
                                     [NSString stringWithFormat:@"%d", remotePort]
                                ]
     ];
    
    NSString* connectingString = [NSString stringWithFormat:@"Proxy: Connecting ..."];
    [statusItem setImage:inStatusImage];
    [statusItem setAlternateImage:inStatusInverseImage];
    [statusMenuItem setTitle:connectingString];
    
    // TODO: CATCH TASK EXCEPTION
    
    [turnOnMenuItem setHidden:YES];
    [turnOnMenuItem setEnabled:NO];
    
    [turnOffMenuItem setHidden:NO];
    [turnOffMenuItem setEnabled:YES];
    
    task = [[NSTask alloc] init];
    
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
    [fh waitForDataInBackgroundAndNotify];
    
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    [nc addObserver:self
           selector:@selector(dataReady:) name:NSFileHandleDataAvailableNotification
             object:fh];
    [nc addObserver:self
           selector:@selector(taskTerminated:) name:NSTaskDidTerminateNotification
             object:task];
    
    // delete askpass lock file
    NSString* lockFile= [userHome stringByAppendingPathComponent:@".sshproxy_askpass_lock"];
    [[NSFileManager defaultManager] removeItemAtPath:lockFile error:nil];
    
    [task launch];
}

- (void)set2connected
{
    proxyStatus = SSHPROXY_CONNECTED;
    [statusItem setImage:onStatusImage];
    [statusItem setAlternateImage:onStatusInverseImage];
    [statusMenuItem setTitle:@"Proxy: On"];
}

- (void)set2reconnect:(NSString*) state
{
    [statusItem setImage:inStatusImage];
    [statusItem setAlternateImage:inStatusInverseImage];
    [statusMenuItem setTitle:[NSString stringWithFormat:@"Proxy: Reconnecting - %@", state]];
    
    // ensure
    [turnOffMenuItem setHidden:NO];
    [turnOffMenuItem setEnabled:YES];
    
    [turnOnMenuItem setHidden:YES];
    [turnOnMenuItem setEnabled:NO];
}

- (void)reconnectIfNeed:(NSString*) state
{
    if (proxyStatus==SSHPROXY_CONNECTED) {
        [self set2reconnect:state];
        [self performSelector: @selector(_turnOnProxy) withObject:nil afterDelay: 3.0];
    } else {
        if (proxyStatus==SSHPROXY_OFF) {
            [statusMenuItem setTitle:@"Proxy: Off"];
        } else {
            [statusMenuItem setTitle:[NSString stringWithFormat:@"Proxy: Off - %@", state]];
        }
    }
}

- (void)dataReady:(NSNotification *)n
{
    NSFileHandle *fh = [n object];
    NSData *data = [fh availableData];
    
    // only receive data when proxy 
    NSString *s = [[NSString alloc] initWithData:data
                                        encoding:NSUTF8StringEncoding];
    
    // truncate task output to reduce memory consume
    NSInteger fromIndex = [taskOutput length]-256;
    fromIndex = fromIndex > 0 ? fromIndex : 0;
    
    taskOutput = [taskOutput substringFromIndex:fromIndex];
    taskOutput = [taskOutput stringByAppendingString:s];
    DDLogInfo(@"%@",s);
    
    // If the task is running, start reading again
    if (task) {
        if ( [taskOutput rangeOfString:@"Entering interactive session"].location != NSNotFound){
            [self set2connected];
        }
        
        [fh waitForDataInBackgroundAndNotify];
    } else {        
        if ([taskOutput rangeOfString:@"bind: Address already in use"].location != NSNotFound) {
            [statusMenuItem setTitle:@"Proxy: Off - port already in use"];
            return;
        } else if ([taskOutput rangeOfString:@"Permission denied "].location != NSNotFound) {
            [statusMenuItem setTitle:@"Proxy: Off - incorrect password"];
            isPasswordCorrect = NO;
            [self performSelector: @selector(_turnOnProxy) withObject:nil afterDelay: 0.0];
            return;
        } else {
            NSArray* errors = @[
                                @[@"ssh: Could not resolve hostname"   , @"could not resolve hostname"],
                                @[@"Connection refused"                , @"connection refused"],
                                @[@"Timeout,"                          , @"timeout, server not responding"],
                                @[@"timed out"                         , @"connection timed out"],
                                @[@"Write failed: Broken pipe"         , @"disconnected from  remote proxy server"],
                                @[@"Connection closed by remote host"  , @"failed to connect remote proxy server"],
                                @[@"unknown error"                     , @"unknown error"],
                                ];
            for (NSArray* error in errors) {
                if ( ([taskOutput rangeOfString:error[0]].location != NSNotFound) || [error[0]isEqual:@"unknown error"]) {
                    [self reconnectIfNeed:error[1]];
                    break;
                }
            }
        }
    }
}
// When the process is done, we should do some cleanup:
- (void)taskTerminated:(NSNotification *)note
{
    task = nil;

    [statusItem setImage:offStatusImage];
    [statusItem setAlternateImage:offStatusInverseImage];
    
    // ensure
    [turnOffMenuItem setHidden:YES];
    [turnOffMenuItem setEnabled:NO];
    
    // show and enable turn on menu
    [turnOnMenuItem setHidden:NO];
    [turnOnMenuItem setEnabled:YES];
}


- (IBAction)turnOffProxy:(id)sender
{
    proxyStatus = SSHPROXY_OFF;
    [self _turnOffProxy];
}


- (void)_turnOffProxy
{
    DDLogInfo(@"Turn off proxy: %@", taskOutput);
    
    // clear taskOutput buffer
    taskOutput = [[NSString alloc] init];
    
    if (!task) {
        // dead task , do noting
        return;
    }
    
    [task interrupt];
//    [task waitUntilExit];
    task = nil;
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
    [self.preferencesWindowController selectControllerAtIndex:1];
    [self performSelector: @selector(openPreferences:) withObject:self afterDelay: 0.0];
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
    DDLogVerbose(@"%@", encodedURLString);
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

-(IBAction)openMacAppStore:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:
     [NSURL URLWithString:@"macappstore://itunes.apple.com/app/ssh-proxy/id597790822?mt=12"]];
}

- (IBAction)openHelpURL:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:
     [NSURL URLWithString:@"https://github.com/brantyoung/sshproxy/wiki"]];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [task interrupt];
    return NSTerminateNow;
}

@end

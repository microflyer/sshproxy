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

@implementation AppController {
    /* The other stuff :P */
    NSStatusItem *statusItem;
    NSImage *offStatusImage;
    NSImage *offStatusInverseImage;
    NSImage *onStatusImage;
    NSImage *onStatusInverseImage;
    NSImage *inStatusImage;
    NSImage *inStatusInverseImage;
    
    NSTask *task;
    NSPipe *pipe;
    NSString* taskOutput;
    
    int proxyStatus;
    NSString *errorMsg;
}

@synthesize preferencesWindowController;

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
    [NSApp setMainMenu:self.mainMenu];
    
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
    [SSHHelper upgrade1:self.serverArrayController];
    
    [self.cautionMenuItem setHidden:YES];
}

- (void)statusItemClicked
{
    NSMenu* menu = [self.statusMenu copy];
    menu.minimumWidth = 256.0;
    
    NSArray* servers = [SSHHelper getServers];
    NSInteger activatedServerIndex = [SSHHelper getActivatedServerIndex];
    
    if (servers && servers.count>0) {
//        [menu insertItemWithTitle:@"Servers:" action:nil keyEquivalent:@"" atIndex:4];
        
        int i = 0;
        for (NSDictionary* server in servers) {
            NSMenuItem* item = [NSMenuItem alloc];
            item.title = [NSString stringWithFormat:@" %@@%@", [SSHHelper userFromServer:server], [SSHHelper hostFromServer:server]];
            item.action = @selector(switchServer:);
            item.indentationLevel = 1;
            
            item.representedObject = [NSNumber numberWithInt:i];
            
            if (i==activatedServerIndex) {
                [item setState:NSOnState];
            }
            
            [menu insertItem:item atIndex:5+i];
            i++;
        }
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:5+i];
    }
    
    [statusItem popUpStatusItemMenu:menu];
}


- (void)switchServer:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    
    int index = [(NSNumber*)menuItem.representedObject intValue];
    [SSHHelper setActivatedServer:index];
    
    [self _turnOffProxy];
    [self performSelector: @selector(turnOnProxy:) withObject:self afterDelay: 0.0];
}

- (void)reactiveProxy:(id)sender
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // if turnOffMenuItem current state is visible and enabled, then reactive proxy
    if ( !self.turnOffMenuItem.isHidden) {
        [self set2reconnect];
        [self turnOffProxy:sender];
        [self _turnOnProxy];
    }
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
    
    errorMsg = nil;
    [self set2connect];
    
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
        errorMsg = nil;
        [self set2disconnected];
        return;
    }
    
    NSString* remoteHost = [SSHHelper hostFromServer:server];
    NSString* loginName = [SSHHelper userFromServer:server];
    int remotePort = [SSHHelper portFromServer:server];
    NSInteger localPort = [SSHHelper getLocalPort];
    BOOL enableCompression = [SSHHelper isEnableCompress:server];
    BOOL shareSocks = [SSHHelper isShareSOCKS:server];
    
    // Get the path of our Askpass program, which we've included as part of the main application bundle
    NSString *askPassPath = [NSBundle pathForResource:@"SSH Proxy - Ask Password" ofType:@""
                                          inDirectory:[[NSBundle mainBundle] bundlePath]];
    
    
    NSString *encryptedServerInfo = [SSHHelper encryptServerInfo:server];
    
    // This creates a dictionary of environment variables (keys) and their values (objects) to be set in the environment where the task will be run. This environment dictionary will then be accessible to our Askpass program.

    NSMutableDictionary *env = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                NSHomeDirectory(), @"HOME",
                                @":9999", @"DISPLAY",
                                askPassPath, @"SSH_ASKPASS",
                                encryptedServerInfo, @"SSHPROXY_SERVER_INFO",
                                @"1",@"INTERACTION",
                                NSHomeDirectory(), @"SSHPROXY_USER_HOME",
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
    NSMutableArray *arguments = nil;
    BOOL isPublicKeyMode = [SSHHelper authMethodFromServer:server]==OW_AUTH_METHOD_PUBLICKEY;

    if ( isPublicKeyMode ) {
        arguments = [SSHHelper getPublicKeyMethodConnectArgsForServer:server];
    } else {
        arguments = [SSHHelper getPasswordMethodConnectArgs];
    }
    
    if (!arguments) {
        // abort connection
        errorMsg = @"Invalid authentication method or private key does not exist";
        [self set2disconnected];
        return;
    }
    
    NSString *proxyCommandStr = [SSHHelper getProxyCommandStr:server];
    
    if (proxyCommandStr) {
        [arguments addObject:proxyCommandStr];
    }
    
    [arguments addObjectsFromArray:@[
                                     advancedOptions,
                                     [NSString stringWithFormat:@"%@", @(localPort)],
                                     [NSString stringWithFormat:@"%@@%@", loginName, remoteHost],
                                     @"-p",
                                     [NSString stringWithFormat:@"%d", remotePort]
                                ]
     ];
    
    // TODO: CATCH TASK EXCEPTION
    
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
    NSString* lockFile= [NSHomeDirectory() stringByAppendingPathComponent:OW_SSHPROXY_ASKPASS_LOCK];
    [[NSFileManager defaultManager] removeItemAtPath:lockFile error:nil];
    
    [task launch];
}

#pragma mark Set Status Menu State

- (void)set2connect
{
    [statusItem setImage:inStatusImage];
    [statusItem setAlternateImage:inStatusInverseImage];
    [self.statusMenuItem setTitle:@"Proxy: Connecting..."];
    
    [self setCautionMessage];
    
    [self.turnOnMenuItem setHidden:YES];
    [self.turnOffMenuItem setHidden:NO];
}

- (void)set2connected
{
    proxyStatus = SSHPROXY_CONNECTED;
    [statusItem setImage:onStatusImage];
    [statusItem setAlternateImage:onStatusInverseImage];
    [self.statusMenuItem setTitle:@"Proxy: On"];
    
    [self setCautionMessage];
    
    [self.turnOnMenuItem setHidden:YES];
    [self.turnOffMenuItem setHidden:NO];
}

- (void)set2disconnected
{
    [statusItem setImage:offStatusImage];
    [statusItem setAlternateImage:offStatusInverseImage];
    [self.statusMenuItem setTitle:@"Proxy: Off"];
    
    [self setCautionMessage];
    
    [self.turnOffMenuItem setHidden:YES];
    [self.turnOnMenuItem setHidden:NO];
}

- (void)setCautionMessage
{
    if (errorMsg) {
        [self.cautionMenuItem setTitle:errorMsg];
        [self.cautionMenuItem setHidden:NO];
    } else {
        [self.cautionMenuItem setHidden:YES];
    }
}

- (void)set2reconnect
{
    [statusItem setImage:inStatusImage];
    [statusItem setAlternateImage:inStatusInverseImage];
    [self.statusMenuItem setTitle:@"Proxy: Reconnecting..."];
    
    [self setCautionMessage];
    
    [self.turnOffMenuItem setHidden:NO];
    [self.turnOnMenuItem setHidden:YES];
}

- (void)reconnectIfNeed:(NSString*) state
{
    if (proxyStatus==SSHPROXY_CONNECTED) {
        errorMsg = state;
        [self set2reconnect];
        [self performSelector: @selector(_turnOnProxy) withObject:nil afterDelay: 3.0];
    } else {
        if (proxyStatus==SSHPROXY_OFF) { // turn off manually
            errorMsg = nil;
        } else { // by error
            errorMsg = state;
        }
        
        [self set2disconnected];
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
            errorMsg = nil;
            [self set2connected];
        }
        
        [fh waitForDataInBackgroundAndNotify];
    } else {
        if ([taskOutput rangeOfString:@"bind: Address already in use"].location != NSNotFound) {
            errorMsg = @"Port already in use";
            [self set2disconnected];
            return;
        } else if ([taskOutput rangeOfString:@"Permission denied "].location != NSNotFound) {
            NSDictionary *server = [SSHHelper getActivatedServer];
            BOOL isPublicKeyMode = [SSHHelper authMethodFromServer:server]==OW_AUTH_METHOD_PUBLICKEY;

            if (isPublicKeyMode) {
                errorMsg = @"Invalid passphrase or private key";
            } else {
                errorMsg = @"Incorrect password";
            }
            [self set2disconnected];
            return;
        } else {
            NSArray* errors = @[
                                @[@"ssh: Could not resolve hostname"   , @"Could not resolve hostname"],
                                @[@"Connection refused"                , @"Connection refused"],
                                @[@"Timeout,"                          , @"Timeout, server not responding"],
                                @[@"Connection timed out during banner exchange"                     , @"Remote proxy server connection timed out"],
                                @[@"timed out"                         , @"Connection timed out"],
                                @[@"Write failed: Broken pipe"         , @"Disconnected from remote proxy server"],
                                @[@"Connection closed by remote host"  , @"Failed to connect remote proxy server"],
                                @[@"unknown error"                     , @"Unknown error"],
                                ];
            for (NSArray* error in errors) {
                if ( ([taskOutput rangeOfString:[error objectAtIndex:0]].location != NSNotFound) || [[error objectAtIndex:0] isEqual:@"unknown error"]) {
                    [self reconnectIfNeed:[error objectAtIndex:1]];
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

    errorMsg = nil;
    [self set2disconnected];
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
    if (!preferencesWindowController)
    {
        NSViewController *generalViewController = [[GeneralPreferencesViewController alloc] init];
        NSViewController *serversViewController = [[ServersPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, serversViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
        
        NSString *title = NSLocalizedString(@"SSH Proxy Preferences", @"SSH Proxy Preferences");
        preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title delegate:self];
        
        [preferencesWindowController.window setReleasedWhenClosed: NO];
        [[preferencesWindowController.window standardWindowButton:NSWindowZoomButton] setEnabled:NO];
//        preferencesWindowController.window.level = NSFloatingWindowLevel;
    }
    return preferencesWindowController;
}

- (IBAction)openPreferences:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    //    [[self.preferencesWindowController window] makeKeyAndOrderFront:nil];
    //    [[self.preferencesWindowController window] setLevel:NSFloatingWindowLevel];
    [[self.preferencesWindowController window] setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
//    [[self.preferencesWindowController window] center];
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
    
    [self.aboutWindow makeKeyAndOrderFront:nil];
    [self.aboutWindow setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [self.aboutWindow center];
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

- (void)preferencesWindowWillClose:(NSNotification *)notification
{
    self.preferencesWindowController = nil;
}

@end

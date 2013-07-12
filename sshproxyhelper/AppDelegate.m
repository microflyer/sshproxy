//
//  AppDelegate.m
//  sshproxyhelper
//
//  Created by Brant Young on 3/2/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:@"com.codinnstudio.sshproxy"]) {
            alreadyRunning = YES;
        }
    }
    
    if (!alreadyRunning) {
        NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath]
                                stringByDeletingLastPathComponent]
                               stringByDeletingLastPathComponent]
                              stringByDeletingLastPathComponent]
                             stringByDeletingLastPathComponent]; // Removes path down to /Applications/Great.app
        NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath]; // Uses string with bundle binary executable
        [[NSWorkspace sharedWorkspace] launchApplication:binaryPath]; // Launches binary
        //        NSAlert *alert = [NSAlert alertWithMessageText:binaryPath defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"hi"];
        //        [alert runModal]; // Use this NSAlert if your helper does not automatically open your main application to see what path it's trying to open.
        [NSApp terminate:nil]; // Required to kill helper app
    }
    [NSApp terminate:nil];
}

- (void)ttdapplicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath]
                            stringByDeletingLastPathComponent]
                           stringByDeletingLastPathComponent]
                          stringByDeletingLastPathComponent]
                         stringByDeletingLastPathComponent]; // Removes path down to /Applications/Great.app
    NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath]; // Uses string with bundle binary executable
    [[NSWorkspace sharedWorkspace] launchApplication:binaryPath]; // Launches binary
    //        NSAlert *alert = [NSAlert alertWithMessageText:binaryPath defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"hi"];
    //        [alert runModal]; // Use this NSAlert if your helper does not automatically open your main application to see what path it's trying to open.
    [NSApp terminate:nil]; // Required to kill helper app
}

@end

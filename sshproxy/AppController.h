//
//  AppController.h
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GeneralPreferencesViewController.h"
#import "MASPreferencesWindowController.h"
#import "INSOCKSServer.h"
#import "INSOCKSConnection.h"

@interface AppController : NSObject <NSApplicationDelegate, NSMenuDelegate, MASPreferencesWindowDelegate, INSOCKSConnectionDelegate, INSOCKSServerDelegate>

@property (nonatomic, readwrite) MASPreferencesWindowController *preferencesWindowController;

/* Our IBAction which will call the helloWorld method when our connected Menu Item is pressed */

- (IBAction)turnOnProxy:(id)sender;
- (IBAction)turnOffProxy:(id)sender;
- (IBAction)openPreferences:(id)sender;
- (IBAction)openHelpURL:(id)sender;
- (IBAction)openAboutWindow:(id)sender;
- (IBAction)openSendFeedback:(id)sender;
- (IBAction)openMacAppStore:(id)sender;
- (IBAction)switchProxyMode:(id)sender;


/* Our outlets which allow us to access the interface */
@property IBOutlet NSMenu *statusMenu;
@property IBOutlet NSMenuItem* statusMenuItem;
@property IBOutlet NSMenuItem* cautionMenuItem;
@property IBOutlet NSMenuItem* turnOnMenuItem;
@property IBOutlet NSMenuItem* turnOffMenuItem;
@property IBOutlet NSWindow* aboutWindow;
@property IBOutlet NSMenu* mainMenu;
@property IBOutlet NSArrayController* serverArrayController;

- (void)reactiveProxy:(id)sender;

enum {
    SSHPROXY_OFF = 0,
    SSHPROXY_ON,
//    SSHPROXY_DISCONNECTED,
    SSHPROXY_CONNECTED,
};

@end

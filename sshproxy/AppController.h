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

@interface AppController : NSObject <NSApplicationDelegate, NSMenuDelegate> {
    /* Our outlets which allow us to access the interface */
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem* statusMenuItem;
    IBOutlet NSMenuItem* turnOnMenuItem;
    IBOutlet NSMenuItem* turnOffMenuItem;
    IBOutlet NSWindow* aboutWindow;
    IBOutlet NSMenu* mainMenu;
    
    /* The other stuff :P */
    NSStatusItem *statusItem;
    NSImage *offStatusImage;
    NSImage *statusHighlightImage;
    NSImage *onStatusImage;
    NSImage *inStatusImage;
    
    NSTask *task;
    NSPipe *pipe;
    NSString* taskOutput;
    
    int proxyStatus;
    
    MASPreferencesWindowController *_preferencesWindowController;
}

@property (nonatomic, readonly) MASPreferencesWindowController *preferencesWindowController;

/* Our IBAction which will call the helloWorld method when our connected Menu Item is pressed */

- (IBAction)turnOnProxy:(id)sender;

- (IBAction)turnOffProxy:(id)sender;

- (IBAction)openPreferences:(id)sender;

- (IBAction)openHelpURL:(id)sender;
- (IBAction)openAboutWindow:(id)sender;

- (IBAction)openSendFeedback:(id)sender;
- (IBAction)openMacAppStore:(id)sender;

enum {
    SSHPROXY_OFF = 0,
    SSHPROXY_ON,
    SSHPROXY_DISCONNECTED,
    SSHPROXY_CONNECTED,
};

@end

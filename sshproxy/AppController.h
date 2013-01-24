//
//  AppController.h
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"

@interface AppController : NSObject {
    /* Our outlets which allow us to access the interface */
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem* statusMenuItem;
    IBOutlet NSMenuItem* turnOnMenuItem;
    IBOutlet NSMenuItem* turnOffMenuItem;
    
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
}

@property (retain) PreferencesController *preferencesController;

/* Our IBAction which will call the helloWorld method when our connected Menu Item is pressed */
-(IBAction)helloWorld:(id)sender;

-(IBAction)turnOnProxy:(id)sender;

-(IBAction)_turnOnProxy:(id)sender;

-(IBAction)turnOffProxy:(id)sender;

-(IBAction)openPreferences:(id)sender;

-(IBAction)quitApp:(id)sender;

enum {
    CHARM_PROXY_OFF = 0,
    CHARM_PROXY_ON,
    CHARM_PROXY_DISCONNECTED,
    CHARM_PROXY_CONNECTED,
};

@end

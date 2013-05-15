//
//  ServersPreferencesViewController.h
//  sshproxy
//
//  Created by Brant Young on 14/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface ServersPreferencesViewController : NSViewController <MASPreferencesViewController> {
    IBOutlet NSTextField* remoteHostTextField;
    IBOutlet NSTextField* remotePortTextField;
    IBOutlet NSStepper* remotePortStepper;
    
    IBOutlet NSTextField* loginNameTextField;
    IBOutlet NSPanel* advancedPanel;
    IBOutlet NSTableView* serversTableView;
}


- (IBAction) remoteStepperAction:(id)sender;

- (IBAction) closePreferencesWindow:(id)sender;

- (IBAction) duplicateServer:(id)sender;
- (IBAction) addServer:(id)sender;

- (IBAction) showTheSheet:(id)sender;
- (IBAction) endTheSheet:(id)sender;

@property IBOutlet NSArrayController* serverArrayController;

@end

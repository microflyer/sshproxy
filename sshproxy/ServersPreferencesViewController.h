//
//  ServersPreferencesViewController.h
//  sshproxy
//
//  Created by Brant Young on 14/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"
#import <INPopoverController/INPopoverController.h>

@interface ServersPreferencesViewController : NSViewController <MASPreferencesViewController, NSTableViewDelegate> {
}


- (IBAction)remoteStepperAction:(id)sender;

- (IBAction)closePreferencesWindow:(id)sender;

- (IBAction)duplicateServer:(id)sender;
- (IBAction)removeServer:(id)sender;
- (IBAction)addServer:(id)sender;

- (IBAction)showTheSheet:(id)sender;
- (IBAction)endTheSheet:(id)sender;

- (IBAction)togglePasswordHelpPopover:(id)sender;

@property (strong) IBOutlet NSArrayController* serverArrayController;
@property (strong) IBOutlet NSUserDefaultsController *userDefaultsController;

@property (strong) IBOutlet NSTextField* remoteHostTextField;
@property (strong) IBOutlet NSTextField* remotePortTextField;
@property (strong) IBOutlet NSStepper* remotePortStepper;

@property (strong) IBOutlet NSTextField* loginNameTextField;
@property (strong) IBOutlet NSPanel* advancedPanel;
@property (strong) IBOutlet NSTableView* serversTableView;
@property (strong) IBOutlet NSButton *passwordHelpButton;

@property (nonatomic,readonly) INPopoverController *passwordHelpPopoverController;

- (IBAction)applyChanges:(id)sender;
- (IBAction)revertChanges:(id)sender;

@property (nonatomic, readwrite) BOOL isDirty;

@end

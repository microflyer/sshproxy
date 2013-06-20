//
//  PreferencesWindow.h
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MASPreferencesViewController.h"

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController>

- (IBAction)localStepperAction:(id)sender;
- (IBAction)toggleAutoTurnOnProxy:(id)sender;
- (IBAction)toggleLaunchAtLogin:(id)sender;
- (IBAction)closePreferencesWindow:(id)sender;
- (IBAction)applyChanges:(id)sender;
- (IBAction)revertChanges:(id)sender;

@property IBOutlet NSTextField* localPortTextField;
@property IBOutlet NSStepper* localPortStepper;
@property IBOutlet NSButton* autoConnectButton;
@property IBOutlet NSButton* startAtLoginButton;
@property IBOutlet NSButton* revertButton;
@property IBOutlet NSButton* applyButton;
@property IBOutlet NSUserDefaultsController *userDefaultsController;

@property (nonatomic, readwrite) BOOL isDirty;

@end
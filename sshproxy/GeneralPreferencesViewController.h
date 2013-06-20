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
{
    IBOutlet NSTextField* localPortTextField;
    IBOutlet NSStepper* localPortStepper;
    
    IBOutlet NSButton* autoConnectButton;
    
    IBOutlet NSButton* startAtLoginButton;
    IBOutlet NSButton* revertButton;
    IBOutlet NSButton* applyButton;
    
    IBOutlet NSUserDefaultsController *userDefaultsController;
}

- (IBAction)localStepperAction:(id)sender;

- (IBAction)toggleAutoTurnOnProxy:(id)sender;

- (IBAction)toggleLaunchAtLogin:(id)sender;

- (IBAction)closePreferencesWindow:(id)sender;

- (IBAction)applyChanges:(id)sender;
- (IBAction)revertChanges:(id)sender;

@property (nonatomic, readwrite) BOOL isDirty;

@end
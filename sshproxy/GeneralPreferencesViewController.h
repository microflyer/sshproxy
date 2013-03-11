//
//  PreferencesWindow.h
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MASPreferencesViewController.h"

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController> {
    IBOutlet NSTextField* remoteHostTextField;
    IBOutlet NSTextField* remotePortTextField;
    IBOutlet NSStepper* remotePortStepper;
    
    IBOutlet NSTextField* loginNameTextField;
    IBOutlet NSTextField* localPortTextField;
    IBOutlet NSStepper* localPortStepper;
    
    IBOutlet NSButton* autoConnectButton;
    
    IBOutlet NSButton* startAtLoginButton;
    IBOutlet NSPanel* advancedPanel;
}

-(IBAction)remoteStepperAction:(id)sender;

-(IBAction)localStepperAction:(id)sender;

-(IBAction)toggleLaunchAtLogin:(id)sender;

-(IBAction)closePreferencesWindow:(id)sender;

@end
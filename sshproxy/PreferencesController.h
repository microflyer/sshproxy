//
//  PreferencesWindow.h
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PreferencesController : NSWindowController {
    IBOutlet NSTextField* remoteHostTextField;
    IBOutlet NSTextField* remotePortTextField;
    IBOutlet NSTextField* localPortTextField;
    IBOutlet NSTextField* loginNameTextField;
    IBOutlet NSButton* saveButton;
    IBOutlet NSButton* autoConnectButton;
    IBOutlet NSPanel* advancedPanel;
    
    int remotePort_;
    int localPort_;
//    NSString* remoteHost_;
}

@property (nonatomic, readwrite) int remotePort;
@property (nonatomic, readwrite) int localPort;
//@property (nonatomic, copy) NSString* remoteHost;

-(IBAction)save:(id)sender;

@end
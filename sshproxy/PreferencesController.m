//
//  PreferencesController
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "PreferencesController.h"
#import "CharmNumberFormatter.h"

@implementation PreferencesController

@synthesize remotePort = remotePort_;
@synthesize localPort = localPort_;
//@synthesize remoteHost;

//-(id)init {
//    
//    return self;
//}
//
//-(void)windowWillClose:(NSNotification *)notification
//{
//    [[NSUserDefaults standardUserDefaults] synchronize];
////    [self release];
//}

-(void)awakeFromNib
{
    CharmNumberFormatter *formatter = [[CharmNumberFormatter alloc] init];
    [remotePortTextField setFormatter:formatter];
    [localPortTextField setFormatter:formatter];
    
    NSString* remoteHost = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"remote_host"];
    if (remoteHost) {
        [remoteHostTextField setStringValue:remoteHost];
        [saveButton setEnabled: YES];
    } else {
        [saveButton setEnabled: NO];
    }
    [saveButton setBezelStyle:NSRoundedBezelStyle];
    [saveButton setKeyEquivalent:@"\r"];
//    [[self window] setDefaultButtonCell:[saveButton cell]];
    
    NSString* loginName = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"login_name"];
    if (loginName) {
        [loginNameTextField setStringValue:loginName];
    }
    
    self.remotePort = [[NSUserDefaults standardUserDefaults] integerForKey:@"remote_port"];
    if (self.remotePort<=0 || self.remotePort>65535) {
        self.remotePort = 22;
    }
    [remotePortTextField setIntValue:self.remotePort];
    
    self.localPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
    if (self.localPort<=0 || self.localPort>65535) {
        self.localPort = 7070;
    }
    [localPortTextField setIntValue:self.localPort];
    
    NSInteger state = [[NSUserDefaults standardUserDefaults] boolForKey:@"disable_autoconnect"] ? NSOffState:NSOnState;
    [autoConnectButton setState:state];
}

-(IBAction)save:(id)sender {
//    int remotePort = remoteHostTextField
    
    [[NSUserDefaults standardUserDefaults] setObject:[remoteHostTextField stringValue] forKey:@"remote_host"];
    [[NSUserDefaults standardUserDefaults] setInteger:[remotePortTextField intValue] forKey:@"remote_port"];
    [[NSUserDefaults standardUserDefaults] setObject:[loginNameTextField stringValue] forKey:@"login_name"];
    [[NSUserDefaults standardUserDefaults] setInteger:[localPortTextField intValue] forKey:@"local_port"];
    [[NSUserDefaults standardUserDefaults] setBool:[autoConnectButton state] == NSOffState forKey:@"disable_autoconnect"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.window performClose:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if ([[remoteHostTextField stringValue]length]>0) {
        [saveButton setEnabled: YES];
    }
    else {
        [saveButton setEnabled: NO];
    }
}


@end

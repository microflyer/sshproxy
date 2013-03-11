//
//  PreferencesController
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//
#import <ServiceManagement/ServiceManagement.h>

#import "GeneralPreferencesViewController.h"
#import "CharmNumberFormatter.h"

@implementation GeneralPreferencesViewController

#pragma mark -
#pragma mark MASPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral]; // NSImageNameNetwork
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

-(void)awakeFromNib
{
    CharmNumberFormatter *formatter = [[CharmNumberFormatter alloc] init];
    [remotePortTextField setFormatter:formatter];
    [localPortTextField setFormatter:formatter];
    
    NSInteger remotePort = [[NSUserDefaults standardUserDefaults] integerForKey:@"remote_port"];
    if (remotePort<=0 || remotePort>65535) {
        remotePort = 22;
    }
    [remotePortTextField setIntegerValue:remotePort];
    
    NSInteger localPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
    if (localPort<=0 || localPort>65535) {
        localPort = 7070;
    }
    [localPortTextField setIntegerValue:localPort];
    
    [remotePortStepper setIntegerValue:remotePort];
    [localPortStepper setIntegerValue:localPort];
}

- (IBAction)remoteStepperAction:(id)sender {
	[remotePortTextField setIntValue: [remotePortStepper intValue]];
}

- (IBAction)localStepperAction:(id)sender {
	[localPortTextField setIntValue: [localPortStepper intValue]];
}

- (IBAction) showTheSheet:(id)sender {
    [NSApp beginSheet:advancedPanel
       modalForWindow:self.view.window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

-(IBAction)endTheSheet:(id)sender {
    [NSApp endSheet:advancedPanel];
    [advancedPanel orderOut:sender];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)toggleLaunchAtLogin:(id)sender
{
    NSInteger state = [startAtLoginButton state] ;
    if (state == NSOnState) { // ON
        // Turn on launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.codinnstudio.sshproxyhelper", YES)) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Couldn't add SSH Proxy Helper App to launch at login item list."];
            [alert runModal];
        }
    }
    if (state == NSOffState) { // OFF
        // Turn off launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.codinnstudio.sshproxyhelper", NO)) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Couldn't remove SSH Proxy Helper App from launch at login item list."];
            [alert runModal];
        }
    }
}

-(IBAction)closePreferencesWindow:(id)sender {
    [self.view.window orderOut:nil];
}


@end

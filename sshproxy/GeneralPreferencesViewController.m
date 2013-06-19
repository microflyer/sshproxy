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

@synthesize isDirty;

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
    [localPortTextField setFormatter:formatter];
    
    NSInteger localPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
    if (localPort<=0 || localPort>65535) {
        localPort = 7070;
    }
    [localPortTextField setIntegerValue:localPort];
    
    [localPortStepper setIntegerValue:localPort];
    
    self.isDirty = NO;
    
    [self addObserver:self forKeyPath:@"isDirty" options:NSKeyValueObservingOptionNew context:NULL];
}

- (IBAction)localStepperAction:(id)sender {
	[localPortTextField setIntValue: [localPortStepper intValue]];
    self.isDirty = userDefaultsController.hasUnappliedChanges;
}

- (IBAction)toggleAutoTurnOnProxy:(id)sender
{
    self.isDirty = userDefaultsController.hasUnappliedChanges;
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
    self.isDirty = userDefaultsController.hasUnappliedChanges;
}

-(IBAction)closePreferencesWindow:(id)sender
{
    [self.view.window orderOut:nil];
}

- (IBAction)applyChanges:(id)sender
{
    [userDefaultsController save:self];
    self.isDirty = NO;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"isDirty"];
}

- (BOOL)isDirty
{
    return isDirty;
}
- (void)setIsDirty:(BOOL)dirty
{
    isDirty = dirty;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    self.isDirty = userDefaultsController.hasUnappliedChanges;
    
    [super controlTextDidChange:aNotification];
}

@end

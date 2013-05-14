//
//  ServersPreferencesViewController.m
//  sshproxy
//
//  Created by Brant Young on 14/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "ServersPreferencesViewController.h"

@implementation ServersPreferencesViewController

#pragma mark -
#pragma mark MASPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"ServersPreferencesView" bundle:nil];
}

- (NSString *)identifier
{
    return @"ServersPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameNetwork];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Servers", @"Toolbar item name for the Servers preference pane");
}

//-(void)awakeFromNib
//{
//    CharmNumberFormatter *formatter = [[CharmNumberFormatter alloc] init];
//    [remotePortTextField setFormatter:formatter];
//    [localPortTextField setFormatter:formatter];
//    
//    NSInteger remotePort = [[NSUserDefaults standardUserDefaults] integerForKey:@"remote_port"];
//    if (remotePort<=0 || remotePort>65535) {
//        remotePort = 22;
//    }
//    [remotePortTextField setIntegerValue:remotePort];
//    
//    NSInteger localPort = [[NSUserDefaults standardUserDefaults] integerForKey:@"local_port"];
//    if (localPort<=0 || localPort>65535) {
//        localPort = 7070;
//    }
//    [localPortTextField setIntegerValue:localPort];
//    
//    [remotePortStepper setIntegerValue:remotePort];
//    [localPortStepper setIntegerValue:localPort];
//}

@end

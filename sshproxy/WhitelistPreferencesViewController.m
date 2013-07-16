//
//  WhitelistPreferencesViewController.m
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "WhitelistPreferencesViewController.h"

@interface WhitelistPreferencesViewController ()

@end

@implementation WhitelistPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"WhitelistPreferencesView" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"WhitelistPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Whitelist", @"Toolbar item name for the Whitelist preference pane");
}

@end

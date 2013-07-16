//
//  WhitelistPreferencesViewController.h
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface WhitelistPreferencesViewController : NSViewController <MASPreferencesViewController, NSTableViewDelegate>

@property (strong) IBOutlet NSArrayController *whitelistArrayController;
@property (strong) IBOutlet NSUserDefaultsController *userDefaultsController;
@property (strong) IBOutlet NSTableView *whitelistTableView;

@property (nonatomic, readwrite) BOOL isDirty;

- (IBAction)closePreferencesWindow:(id)sender;
- (IBAction)applyChanges:(id)sender;
- (IBAction)revertChanges:(id)sender;

- (IBAction)duplicateSite:(id)sender;
- (IBAction)removeSite:(id)sender;
- (IBAction)addSite:(id)sender;

- (IBAction)cellButtonClicked:(id)sender;

@end

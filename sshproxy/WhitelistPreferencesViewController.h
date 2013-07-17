//
//  WhitelistPreferencesViewController.h
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

enum {
    OW_IMPORT_GOOGLE_SITES = 1,
    OW_IMPORT_TWITTER_SITES,
    OW_IMPORT_FACEBOOK_SITES,
    OW_IMPORT_YOUTUBE_SITES,
    OW_IMPORT_BLOGGER_SITES,
    OW_IMPORT_WORDPRESS_SITES,
    OW_IMPORT_URLSHORTTEN_SITES,
};

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
- (IBAction)importMenuClicked:(id)sender;

@end

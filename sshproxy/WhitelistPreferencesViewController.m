//
//  WhitelistPreferencesViewController.m
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "WhitelistPreferencesViewController.h"
#import "WhitelistHelper.h"

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

-(void)loadView
{
    [super loadView];
    
    [self.userDefaultsController save:self];
    self.isDirty = NO;
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

#pragma - Actions

- (IBAction)closePreferencesWindow:(id)sender {
    [self.view.window performClose:sender];
}

- (IBAction)applyChanges:(id)sender
{
    // rember index
    NSUInteger selected = self.whitelistArrayController.selectionIndex;
    
    // remove duplicates
    NSArray *sites = [NSArray arrayWithArray:[[NSSet setWithArray:self.whitelistArrayController.arrangedObjects] allObjects]];
    
    NSRange range = NSMakeRange(0, [[self.whitelistArrayController arrangedObjects] count]);
    [self.whitelistArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    
    [self.whitelistArrayController addObjects:sites];
    
    // apply changes
    [self.userDefaultsController save:self];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.isDirty = NO;
    
    if ( [self.whitelistArrayController.arrangedObjects count] <= 0) {
        return;
    }

    // recover selection
    if (selected >= [self.whitelistArrayController.arrangedObjects count]) {
        selected = [self.whitelistArrayController.arrangedObjects count] -1;
    }
    
    self.whitelistArrayController.selectionIndex = selected;
    [self.whitelistTableView scrollRowToVisible:selected];
}
- (IBAction)revertChanges:(id)sender
{
    NSUInteger selected = self.whitelistArrayController.selectionIndex;
    
    [self.userDefaultsController revert:self];
    
    // save again to prevent dirty settings
    [self.userDefaultsController save:self];
    [self.userDefaultsController.defaults synchronize];
    
    self.isDirty = NO;
    
    if (selected >= [self.whitelistArrayController.arrangedObjects count]) {
        selected = [self.whitelistArrayController.arrangedObjects count] -1;
    }
    
    self.whitelistArrayController.selectionIndex = selected;
    [self.whitelistTableView scrollRowToVisible:selected];
}


- (void)_addSite:(NSDictionary*)server
{
    [self.whitelistArrayController addObject:server];
    
    NSInteger index = [self.whitelistTableView numberOfRows]-1;
    [self.whitelistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    
    [self.whitelistTableView scrollRowToVisible:index];
    [self.whitelistTableView editColumn:1 row:index withEvent:nil select:YES];
}

- (IBAction)removeSite:(id)sender
{
    NSInteger count = [self.whitelistTableView numberOfRows];
    
    NSUInteger index = [self.whitelistArrayController selectionIndex];
    [self.whitelistArrayController removeObjectAtArrangedObjectIndex:index];
    
    if (index==(count-1)) {
        index = index -1;
    }
    
    [self.whitelistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self.whitelistTableView scrollRowToVisible:index];
    
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)addSite:(id)sender
{
    NSDictionary* emptySite = [WhitelistHelper newSite:nil];
    
    [self _addSite:emptySite];
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)duplicateSite:(id)sender
{
    NSDictionary* site = (NSDictionary*)[self.whitelistArrayController.selectedObjects objectAtIndex:0];
    [self _addSite:[site copy]];
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)cellButtonClicked:(id)sender
{
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

#pragma - NSViewController

- (BOOL)commitEditing
{
    BOOL shouldClose = YES;
    
    if (self.isDirty) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"The preference has changes that have not been applied. Would you like to apply them?" defaultButton:@"Apply" alternateButton:@"Don't Apply" otherButton:@"Cancel" informativeTextWithFormat:@""];
        
        alert.alertStyle = NSWarningAlertStyle;
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        
        // a simple trick for waiting sheet modal return
        shouldClose = [NSApp runModalForWindow:alert.window];
    }
    
    return shouldClose;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    switch (returnCode) {
        case NSAlertDefaultReturn: // apply
            [self performSelector: @selector(applyChanges:) withObject:nil afterDelay: 0.0];
            [NSApp stopModalWithCode:YES];
            break;
            
        case NSAlertOtherReturn: // cancel
            [NSApp stopModalWithCode:NO];
            break;
            
        case NSAlertAlternateReturn: // don't apply
            [self performSelector: @selector(revertChanges:) withObject:nil afterDelay: 0.0];
            [NSApp stopModalWithCode:YES];
            break;
            
        default:
            [NSApp stopModalWithCode:YES];
            break;
    }
}

#pragma mark - NSControl

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

#pragma mark - Import sites

- (void)_importSite:(NSString *)address
{
    NSDictionary *site = [WhitelistHelper newSite:address];
    [self _addSite:site];
}

- (IBAction)importMenuClicked:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;
    
    switch (menuItem.tag) {
        case OW_IMPORT_GOOGLE_SITES:
            // http://en.wikipedia.org/wiki/List_of_Google_domains
            [self _importSite:@"google.com"];
            [self _importSite:@"google-analytics.com"];
            [self _importSite:@"feedburner.com"];
            [self _importSite:@"gmail.com"];
            [self _importSite:@"appspot.com"];
            [self _importSite:@"googleusercontent.com"];
            break;
            
        case OW_IMPORT_TWITTER_SITES:
            [self _importSite:@"twitter.com"];
            [self _importSite:@"twimg.com"];
            [self _importSite:@"t.co"];
            break;
            
        case OW_IMPORT_FACEBOOK_SITES:
            [self _importSite:@"facebook.com"];
            [self _importSite:@"ff.im"];
            [self _importSite:@"fbcdn.net"];
            break;
            
        case OW_IMPORT_YOUTUBE_SITES:
            [self _importSite:@"youtube.com"];
            [self _importSite:@"youtu.be"];
            [self _importSite:@"ytimg.com"];
            [self _importSite:@"y2u.be"];
            break;
            
        case OW_IMPORT_BLOGGER_SITES:
            [self _importSite:@"blogger.com"];
            [self _importSite:@"blogcdn.com"];
            [self _importSite:@"blogspot.com"];
            break;
            
        case OW_IMPORT_WORDPRESS_SITES:
            [self _importSite:@"wordpress.com"];
            [self _importSite:@"wp.com"];
            break;
            
        case OW_IMPORT_URLSHORTTEN_SITES:
            [self _importSite:@"j.mp"];
            [self _importSite:@"bit.ly"];
            [self _importSite:@"bitly.com"];
            [self _importSite:@"tinyurl.com"];
            [self _importSite:@"ow.ly"];
            [self _importSite:@"dft.ba"];
            [self _importSite:@"goo.gl"];
            [self _importSite:@"is.gd"];
            break;
        
        // case others:
        // http://en.wikipedia.org/wiki/List_of_websites_blocked_in_the_People%27s_Republic_of_China
            
        default:
            break;
    }
    
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

@end

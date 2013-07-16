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
    
    // apply changes
    [self.userDefaultsController save:self];
    [self.userDefaultsController.defaults synchronize];
    
    self.isDirty = NO;
    
    if ( [self.whitelistArrayController.arrangedObjects count] <= 0) {
        return;
    }

    // recover selection
    if (selected >= [self.whitelistArrayController.arrangedObjects count]) {
        selected = [self.whitelistArrayController.arrangedObjects count] -1;
    }
    
    self.whitelistArrayController.selectionIndex = selected;
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
}


- (void)_addSite:(NSDictionary*)server
{
    [self.whitelistArrayController addObject:server];
    
    NSInteger index = [self.whitelistTableView numberOfRows]-1;
    [self.whitelistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    
    [self.whitelistTableView scrollRowToVisible:index];
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
    NSMutableDictionary* emptySite = [[NSMutableDictionary alloc] init];
    
    [emptySite setObject:@"example.com" forKey:@"address"];
    [emptySite setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    [emptySite setObject:[NSNumber numberWithBool:YES] forKey:@"subdomains"];
    
    [self _addSite:emptySite];
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)duplicateSite:(id)sender
{
    NSDictionary* site = (NSDictionary*)[self.whitelistArrayController.selectedObjects objectAtIndex:0];
    [self _addSite:[site mutableCopy]];
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

@end

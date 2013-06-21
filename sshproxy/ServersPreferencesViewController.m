//
//  ServersPreferencesViewController.m
//  sshproxy
//
//  Created by Brant Young on 14/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "ServersPreferencesViewController.h"
#import "CharmNumberFormatter.h"
#import "SSHHelper.h"
#import "PasswordHelpViewController.h"
#import "AppController.h"

@implementation ServersPreferencesViewController

@synthesize passwordHelpPopoverController;
@synthesize isDirty;

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

- (void)loadView
{
    [super loadView];
    
    CharmNumberFormatter *formatter = [[CharmNumberFormatter alloc] init];
    [self.remotePortTextField setFormatter:formatter];
    
    if ([self.serversTableView numberOfRows]<=0) {
        [self performSelector: @selector(addServer:) withObject:self afterDelay: 0.0f];
    } else {
        NSInteger index = [SSHHelper getActivatedServerIndex];
        [self.serversTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
        
        // invoke tableViewSelectionDidChange
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewSelectionDidChangeNotification object:self.serversTableView];
    }
    
    [self.userDefaultsController save:self];
    self.isDirty = NO;
}

- (IBAction)remoteStepperAction:(id)sender
{
	self.remotePortTextField.intValue = self.remotePortStepper.intValue;
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)showTheSheet:(id)sender
{
    [NSApp beginSheet:self.advancedPanel
       modalForWindow:self.view.window
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}

- (IBAction)endTheSheet:(id)sender
{
    [NSApp endSheet:self.advancedPanel];
    [self.advancedPanel orderOut:sender];
    
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}


- (IBAction)togglePasswordHelpPopover:(id)sender
{
    if (self.passwordHelpPopoverController.popoverIsVisible) {
        [self.passwordHelpPopoverController closePopover:nil];
    } else {
        [self.passwordHelpPopoverController presentPopoverFromRect:[sender bounds] inView:sender preferredArrowDirection:INPopoverArrowDirectionLeft anchorsToPositionView:YES];
    }
}


- (void)_addServer:(NSDictionary*)server
{
    [self.serverArrayController addObject:server];
    
    NSInteger index = [self.serversTableView numberOfRows]-1;
    [self.serversTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    
    [self.remoteHostTextField becomeFirstResponder];
    [self.serversTableView scrollRowToVisible:index];
}

- (IBAction)removeServer:(id)sender
{
    NSInteger count = [self.serversTableView numberOfRows];
    
    NSUInteger index = [self.serverArrayController selectionIndex];
    [self.serverArrayController removeObjectAtArrangedObjectIndex:index];
    
    if (index==(count-1)) {
        index = index -1;
    }
    
    [self.serversTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self.serversTableView scrollRowToVisible:index];
    
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)addServer:(id)sender
{
    NSMutableDictionary* defaultServer = [[NSMutableDictionary alloc] init];
    
    [defaultServer setObject:@"example.com" forKey:@"remote_host"];
    [defaultServer setObject:[NSNumber numberWithInt:22] forKey:@"remote_port"];
    [defaultServer setObject:@"user" forKey:@"login_name"];
    [defaultServer setObject:[NSNumber numberWithBool:NO] forKey:@"enable_compression"];
    [defaultServer setObject:[NSNumber numberWithBool:NO] forKey:@"share_socks"];
    
    [self _addServer:defaultServer];
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)duplicateServer:(id)sender
{
    NSDictionary* server = (NSDictionary*)[self.serverArrayController selectedObjects][0];
    [self _addServer:server];
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)closePreferencesWindow:(id)sender {
    [self.view.window performClose:sender];
}

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

- (INPopoverController *)passwordHelpPopoverController
{
    if (!passwordHelpPopoverController) {
        PasswordHelpViewController *viewController = [[PasswordHelpViewController alloc] init];
    
        passwordHelpPopoverController = [[INPopoverController alloc] initWithContentViewController:viewController];
    }
    
    return passwordHelpPopoverController;
}

- (IBAction)applyChanges:(id)sender
{
    NSInteger index = [SSHHelper getActivatedServerIndex];
    NSDictionary* server = (NSDictionary*)[self.serverArrayController arrangedObjects][index];
    BOOL isProxyNeedReactive = ![server isEqualToDictionary:[SSHHelper getActivatedServer]];
    
    NSInteger selected = self.serverArrayController.selectionIndex;
    
    [self.userDefaultsController save:self];
    [self.userDefaultsController.defaults synchronize];
    
    self.isDirty = NO;
    
    [self.serversTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
        
    // reactive proxy
    if (isProxyNeedReactive) {
        AppController *appController = (AppController *)([NSApplication sharedApplication].delegate);
        
        // it seems must delay some microsenconds to wait user defaults synchronize
        [appController performSelector: @selector(reactiveProxy:) withObject:self afterDelay: 0.1];
    }

}
- (IBAction)revertChanges:(id)sender
{
    NSInteger selected = self.serverArrayController.selectionIndex;
    
    [self.userDefaultsController revert:self];
    
    // save again to prevent dirty settings
    [self.userDefaultsController save:self];
    [self.userDefaultsController.defaults synchronize];
    
    self.isDirty = NO;
    
    [self.serversTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

@end

//
//  CharmTextField.m
//  sshproxy
//
//  Created by Brant Young on 14/4/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "CharmTextField.h"

@implementation CharmTextField

- (void)setEnabled:(BOOL)flag
{
    [super setEnabled:flag];
    
    if (flag == NO) {
        [self setTextColor:[NSColor disabledControlTextColor]];
    } else {
        [self setTextColor:[NSColor controlTextColor]];
    }
}

@end

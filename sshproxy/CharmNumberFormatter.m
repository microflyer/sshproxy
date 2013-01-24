//
//  CharmNumberFormatter.m
//  sshproxy
//
//  Created by Brant Young on 17/1/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "CharmNumberFormatter.h"

@implementation CharmNumberFormatter

- (id)init {
    self = [super init];
    if (self) {
//        [self setMinimum:[NSDecimalNumber decimalNumberWithString:@"0"]];
//        [self setMaximum:[NSDecimalNumber decimalNumberWithString:@"80"]];
//        [self setNumberStyle:NSNumberFormatterDecimalStyle];
    }
    return self;
}


- (BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if([partialString length] == 0) {
        return YES;
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:partialString];
    int value = 0;
    
    if(!([scanner scanInt:&value] && [scanner isAtEnd])) {
        NSBeep();
        return NO;
    }
    
    if (value>65535) {
        NSBeep();
        return NO;
    }
    
    return YES;
}

@end

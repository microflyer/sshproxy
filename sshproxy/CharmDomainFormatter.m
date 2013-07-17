//
//  CharmDomainFormatter.m
//  sshproxy
//
//  Created by Brant Young on 7/16/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//

#import "CharmDomainFormatter.h"

@implementation CharmDomainFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    NSURL *url = [NSURL URLWithString:anObject];
    
    if (url.host) {
        return url.host.lowercaseString;
    }
    
    return [url absoluteString].lowercaseString;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    if (anObject)
    {
        *anObject = string.lowercaseString;
    }
    
    return YES;
}

@end

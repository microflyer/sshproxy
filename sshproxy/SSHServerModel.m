//
//  SSHServerModel.m
//  sshproxy
//
//  Created by Brant Young on 13/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import "SSHServerModel.h"

@implementation SSHServerModel

@synthesize remoteHost;
@synthesize remotePort;
@synthesize loginName;
@synthesize enableCompression;
@synthesize shareSocks;

- (id)init {
    self = [super init];
    if (self) {
        self.remoteHost = [[NSString alloc] init];
        self.remotePort = [[NSString alloc] init];
        self.loginName = [[NSString alloc] init];
        self.enableCompression = NO;
        self.shareSocks = NO;
    }
    return self;
}

@end

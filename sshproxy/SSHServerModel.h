//
//  SSHServerModel.h
//  sshproxy
//
//  Created by Brant Young on 13/5/13.
//  Copyright (c) 2013 Charm Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSHServerModel : NSObject

@property(readwrite, copy) NSString	*remoteHost;
@property(readwrite, copy) NSString	*remotePort;
@property(readwrite, copy) NSString	*loginName;
@property(readwrite, assign) BOOL enableCompression;
@property(readwrite, assign) BOOL shareSocks;

@end

//
//  GLUdpConnection.h
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

extern NSString *const GLMapAttackHostname;
extern const int GLMapAttackPort;

@interface GLUdpConnection : NSObject <GCDAsyncUdpSocketDelegate>

@property (strong, nonatomic) NSString *hostname;
@property (strong, nonatomic) NSError *lastError;

+ (GLUdpConnection *)getConnectionForHostname:(NSString *)hostname;
+ (GLUdpConnection *)getConnection;

- (BOOL)connect;
- (void)sendDictionary:(NSDictionary *)dictionary;

@end

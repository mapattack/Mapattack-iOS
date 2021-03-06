//
//  MAUdpConnection.h
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

/*
 
 quick start example:
 
    MAUdpConnection *udp = [MAUdpConnection connectionForHostname:@"192.168.56.160" delegate:self];
    [udp connect];
    [udp beginReceiving];
    [udp sendDictionary:@{@"foo": @42, @"bar": @[@1,@2,@3], @"bat": @YES}];
 
 */

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

@class MAUdpConnection;

@protocol MAUdpConnectionDelegate <NSObject>
@optional
- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveDictionary:(NSDictionary *)dictionary;
- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveArray:(NSArray *)array;
@end

@interface MAUdpConnection : NSObject <GCDAsyncUdpSocketDelegate>

@property (strong, nonatomic) NSError *lastError;
@property (weak, nonatomic) id <MAUdpConnectionDelegate> delegate;

- (id)initWithDelegate:(id <MAUdpConnectionDelegate>)delegate;

- (BOOL)connect;

- (void)disconnect;

- (void)sendDictionary:(NSDictionary *)dictionary;
- (void)beginReceiving;

@end


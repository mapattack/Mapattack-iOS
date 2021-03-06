//
//  MAGameManager.h
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AFNetworking/AFNetworking.h>
#import "MAUdpConnection.h"

@class MAUdpConnection;
@class AFHTTPSessionManager;
@class MAGameManager;
@class MAPlayer;
@class MACoin;
@class MABoard;

@protocol MAGameManagerDelegate
- (void)team:(NSString *)color didReceivePoints:(NSInteger)points;
- (void)team:(NSString *)color setScore:(NSInteger)score;

- (void)updateStateForPlayer:(MAPlayer *)player;
- (void)updateStateForCoin:(MACoin *)coin;

- (void)gameDidStart;
- (void)gameDidEnd;
@end

@interface MAGameManager : NSObject <CLLocationManagerDelegate, MAUdpConnectionDelegate>
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) MAUdpConnection *udpConnection;
@property (strong, nonatomic, readonly) NSString *joinedTeamColor;
@property (strong, nonatomic, readonly) MABoard *joinedGameBoard;
@property (assign, nonatomic, readonly) NSInteger redScore;
@property (assign, nonatomic, readonly) NSInteger blueScore;
@property (weak, nonatomic) id <MAGameManagerDelegate, NSObject> delegate;

+ (MAGameManager *)sharedManager;

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion;
- (void)registerPushToken:(NSData *)pushToken;
- (void)beginMonitoringNearbyBoardsWithBlock:(void (^)(NSArray *games, NSError *))completion;
- (void)stopMonitoringNearbyGames;

- (void)joinGameOnBoard:(MABoard *)board completion:(void (^)(NSString *joinedTeam, NSError *error))completion;
- (void)createGameForBoard:(MABoard *)board completion:(void (^)(NSString *joinedTeam, NSError *error))completion;
- (void)startGame;
- (void)endGame;
- (void)leaveGame;
- (void)fetchBoardStateForBoardId:(NSString *)boardId completion:(void (^)(MABoard *board, NSArray *coins, NSError *error))completion;
- (void)fetchGameStateForGameId:(NSString *)gameId completion:(void (^)(NSArray *coins, NSError *error))completion;

- (void)startPollingGameState;

- (MKCoordinateRegion)regionForBoard:(MABoard *)board;

- (MKMapRect)mapRectForJoinedBoard;

- (MKMapRect)mapRectForBoard:(MABoard *)board;
@end

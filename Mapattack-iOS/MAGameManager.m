//
//  MAGameManager.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/19/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "GeoHash.h"
#import "MAGameManager.h"

@interface MAGameManager()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocationManager *gameListLocationManager;
@property (strong, nonatomic) MAUdpConnection *udpConnection;
@property (strong, nonatomic) AFHTTPSessionManager *tcpConnection;
@property (copy, nonatomic) void (^listGamesCompletionBlock)(NSArray *games, NSError *error);
@property (strong, nonatomic) NSString *joinedGameId;
@property (strong, nonatomic) NSString *joinedGameName;

@end

@implementation MAGameManager {
    NSString *_accessToken;
}

+ (MAGameManager *)sharedManager {
    static MAGameManager *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;

    self.gameListLocationManager = [[CLLocationManager alloc] init];
    self.gameListLocationManager.delegate = self;
    self.gameListLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    self.gameListLocationManager.distanceFilter = 50;

    self.udpConnection = [[MAUdpConnection alloc] initWithDelegate:self];

    self.tcpConnection = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:kMapAttackURL]];
    self.tcpConnection.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.tcpConnection.responseSerializer = [AFJSONResponseSerializer serializer];

    return self;
}

- (NSString *)accessToken {
    if (!_accessToken) {
        _accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessTokenKey];
    }

    return _accessToken;
}

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveArray:(NSArray *)array {
    DDLogVerbose(@"Received udp array: %@", array);
}

- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveDictionary:(NSDictionary *)dictionary {
    DDLogVerbose(@"Received udp dictionary: %@", dictionary);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!self.accessToken) {
        DDLogError(@"Tried to update locations without an access token!");
        return;
    }

    if (manager == self.gameListLocationManager) {
        DDLogVerbose(@"Fetching nearby games: %@", self.gameListLocationManager.location);
        [self.tcpConnection POST:@"/board/list"
                      parameters:@{
                              @"access_token": self.accessToken,
                              @"latitude": @(self.gameListLocationManager.location.coordinate.latitude),
                              @"longitude": @(self.gameListLocationManager.location.coordinate.longitude)
                      }
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             NSArray *boards = responseObject[@"boards"];

                             DDLogVerbose(@"Found %d board%@ nearby", boards.count, boards.count == 1 ? @"" : @"s");
                             for (NSDictionary *game in boards) {
                                 DDLogVerbose(@"got game: %@", game);
                             }

                             if (self.listGamesCompletionBlock != nil) {
                                 self.listGamesCompletionBlock(boards, nil);
                             }
                         }
                         failure:^(NSURLSessionDataTask *task, NSError *error) {
                             DDLogError(@"Failed to retrieve nearby games: %@", [error debugDescription]);
                             if (self.listGamesCompletionBlock != nil) {
                                 self.listGamesCompletionBlock(nil, error);
                             }
                         }];
        return;
    }

    [locations enumerateObjectsUsingBlock:^(CLLocation *location, NSUInteger idx, BOOL *stop) {
        NSString *locationHash = [GeoHash hashForLatitude:location.coordinate.latitude
                                                longitude:location.coordinate.longitude
                                                   length:9];
        NSDictionary *update = @{
                @"location": locationHash,
                @"timestamp": @(location.timestamp.timeIntervalSince1970),
                @"accuracy": @(location.horizontalAccuracy),
                @"speed": @(location.speed),
                @"bearing": @(location.course),
                @"access_token": self.accessToken
        };
        [self.udpConnection sendDictionary:update];
    }];
}

- (void)beginMonitoringNearbyBoardsWithBlock:(void (^)(NSArray *games, NSError *))completion {
    if (!self.accessToken) {
        DDLogError(@"Tried to get nearby games without an access token!");
        // TODO: Send user back to launch view with an alert telling them to try logging in again.
        return;
    }

    self.listGamesCompletionBlock = completion;
    DDLogVerbose(@"Getting user's location for game list...");
    [self.gameListLocationManager startUpdatingLocation];
}

- (void)stopMonitoringNearbyGames {
    DDLogVerbose(@"Stopping game list location updates.");
    [self.gameListLocationManager stopUpdatingLocation];
    self.listGamesCompletionBlock = nil;
}

- (void)joinGame:(NSDictionary *)game {
    NSString *gameId = game[@"game_id"];
    DDLogVerbose(@"Joining game: %@", gameId);
    [self.tcpConnection POST:@"/game/join"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": gameId
                  }
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error joining game: %@", errorJson);
                             return;
                         }

                         self.joinedGameId = gameId;
                         // TODO: Figure out what exactly should happen here? Check if game is active, start location updates if so, what do if not?
                         // [self.locationManager startUpdatingLocation];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error joining game: %@", [error debugDescription]);
                     }];
}

- (void)createGame:(NSDictionary *)board completion:(void (^)(NSError *error))completion {
    NSString *boardId = board[@"board_id"];
    DDLogVerbose(@"Creating game for board: %@", boardId);
    [self.tcpConnection POST:@"game/create"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"board_id": boardId
                  }
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error creating game: %@", errorJson);
                             if (completion != nil) {
                                 completion([NSError errorWithDomain:@"com.esri.portland.mapattack" code:400 userInfo:errorJson]);
                             }
                             return;
                         }

                         self.joinedGameId = responseObject[@"game_id"];
                         if (completion != nil) {
                             completion(nil);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error creating game: %@", [error debugDescription]);
                         if (completion != nil) {
                             completion(error);
                         }
                     }];
}

- (void)startGame:(NSDictionary *)game {
    [self.tcpConnection POST:@"game/start"
                  parameters:@{
                          @"access_token": self.accessToken,
                          @"game_id": self.joinedGameId
                  }
                     success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error starting game: %@", errorJson);
                             return;
                         }

                         [self.locationManager startUpdatingLocation];
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error starting game: %@", [error debugDescription]);
                     }];
}

- (void)syncGameState {
    [self.tcpConnection POST:@"/game/state"
                  parameters:@{}
                     success:^(NSURLSessionDataTask *task, id responseObject) {
                         NSDictionary *errorJson = responseObject[@"error"];
                         if (errorJson != nil) {
                             DDLogError(@"Error syncing game state: %@", errorJson);
                             return;
                         }

                         NSArray *players = responseObject[@"players"];
                         DDLogVerbose(@"Received state sync for %d players", players.count);
                         for (NSDictionary *player in players) {
                             DDLogVerbose(@"%@", player);
                             if ([self.delegate respondsToSelector:@selector(player:didMoveToLocation:)]) {
                                 // TODO: I'm guessing at what these keys are.
                                 [self.delegate player:player[@"id"]
                                     didMoveToLocation:[[CLLocation alloc] initWithLatitude:[player[@"latitude"] floatValue]
                                                                                  longitude:[player[@"longitude"] floatValue]]];
                             }
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error syncing game state: %@", [error debugDescription]);

                         // TODO: Tell the user about this in some way? Maybe just keep track how many times we fail a sync
                         // and notify the user after missing so many.
                     }];
}

- (void)registerDeviceWithCompletionBlock:(void (^)(NSError *))completion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [defaults objectForKey:kAccessTokenKey];
    NSString *name = [defaults objectForKey:kUserNameKey];
    NSData *avatar = [defaults dataForKey:kAvatarKey];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
            @"name": name,
            @"avatar": [avatar base64EncodedStringWithOptions:0]
    }];
    [params setValue:accessToken forKey:@"access_token"];

    [self.tcpConnection POST:@"/device/register"
                  parameters:params
                     success:^(NSURLSessionDataTask *task, NSDictionary *responseObject) {
                         [defaults setValue:responseObject[@"device_id"] forKey:kDeviceIdKey];
                         [defaults setValue:responseObject[@"access_token"] forKey:kAccessTokenKey];
                         [defaults synchronize];

                         DDLogVerbose(@"Device (%@) registered with token: %@.", responseObject[@"device_id"], responseObject[@"access_token"]);
                         if (completion != nil) {
                             completion(nil);
                         }
                     }
                     failure:^(NSURLSessionDataTask *task, NSError *error) {
                         DDLogError(@"Error registering device: %@", [error debugDescription]);
                         if (completion != nil) {
                             completion(error);
                         }
                     }];
}

@end

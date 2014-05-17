//
//  DSMConnector.h
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/15.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DSMConnectorOffline,        // no login working info
    DSMConnectorLoggingIn,      // logging in
    DSMConnectorConnected,      // logged in
    DSMConnectorReconnecting,   // logging out, changing login
    DSMConnectorLoggingOut      // logging out, going offline
} DSMConnectorState;

@interface DSMConnector : NSObject

@property (readonly) DSMConnectorState state;
@property (readonly, retain) NSString *stateDescription;
@property (readonly) BOOL secure;
@property (readonly, retain) NSString *host;
@property (readonly) NSUInteger port;
@property (readonly, retain) NSString *user;
@property (readonly, retain) NSString *password;

- (id)init;

- (void)createTaskFromFilename:(NSString *)filename data:(NSData *)data handler:(void (^)(NSError *))handler;
- (void)createTaskFromURI:(NSString *)URI handler:(void (^)(NSError *))handler;
- (void)connectSecure:(BOOL)secure host:(NSString *)host port:(NSUInteger)port user:(NSString *)user password:(NSString *)password handler:(void (^)(NSError *))handler;
- (void)logoutImmediately:(BOOL)immediately handler:(void (^)(NSError *))handler;

@end

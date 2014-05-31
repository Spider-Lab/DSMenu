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

extern NSString *DSMConnectorErrorDomain;

enum {
    DSMConnectorNoLoginError = 1,
    DSMConnectorNoPasswordError = 2,
    DSMConnectorNotConnectedError = 3,
    DSMConnectorInvalidReplyError = 4,
    
    DSMConnectorUnknownError = 100,
    DSMConnectorInvalidParameterError = 101,
    DSMConnectorUnknownAPIError = 102,
    DSMConnectorUnknownMethodError = 103,
    DSMConnectorVersionTooLowError = 104, // TODO: improve wording
    DSMConnectorInsuficcientPermissionError = 105,
    DSMConnectorSessionTimedOutError = 106,
    DSMConnectorSessionInterruptedError = 107,
    
    DSMConnectorIncorrectLoginError = 400,
    DSMConnectorGuestAccountDisabledError = 401,
    DSMConnectorAccountDisabledError = 402,
    DSMConnectorWrongPasswordError = 403,
    DSMConnectorPermissionDeniedError = 404
};

@interface DSMConnectorConnectionInfo : NSObject

- (id)initWithSecure:(BOOL)secure host:(NSString *)host port:(NSNumber *)port user:(NSString *)user password:(NSString *)password;
- (id)initWithInfo:(DSMConnectorConnectionInfo *)info;
- (id)initWithUserDefaultsError:(NSError **)error;

- (NSString *)baseURL;
- (BOOL)isValid;
- (BOOL)isEqualToConnectionInfo:(DSMConnectorConnectionInfo *)info;

- (BOOL)saveToUserDefaults;

@property (readwrite, copy) NSString *host;
@property (readwrite) BOOL secure;
@property (readwrite, copy) NSNumber *port;
@property (readwrite, copy) NSString *user;
@property (readwrite, copy) NSString *password;

@end


@interface DSMConnector : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (readonly) DSMConnectorState state;
@property (readonly, retain) NSString *stateDescription;
@property (readonly, retain) DSMConnectorConnectionInfo *connectionInfo;

- (id)init;

- (void)restoreLoginWithHandler:(void (^)(NSError *))handler;

- (void)createTaskFromFilename:(NSString *)filename data:(NSData *)data handler:(void (^)(NSError *))handler;
- (void)createTaskFromURI:(NSString *)URI handler:(void (^)(NSError *))handler;
- (void)connectTo:(DSMConnectorConnectionInfo *)info handler:(void (^)(NSError *))handler;
- (void)logoutImmediately:(BOOL)immediately handler:(void (^)(NSError *))handler;

@end

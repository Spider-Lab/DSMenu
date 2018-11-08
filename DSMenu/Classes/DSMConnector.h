/*
  DSMConnector.h -- implements Download Station API
  Copyright (C) 2014 Dieter Baron
 
  This file is part of DSMenu, a utility for Synology Download Station.
  The authors can be contacted at <dsmenu@spiderlab.at>
 
  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:
  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.
  3. The names of the authors may not be used to endorse or promote
     products derived from this software without specific prior
     written permission.
 
  THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
    DSMConnectorVersionTooLowError = 104,
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

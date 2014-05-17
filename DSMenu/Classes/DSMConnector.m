//
//  DSMConnector.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/15.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMConnector.h"

@interface DSMConnector () {
    NSString *session_id;
    
    void (^logout_completion_handler)(NSError *);
    NSMutableSet *outstanding_requests;
}

// 100: 'Unknown error',
// 101: 'Invalid parameter',
// 102: 'The requested API does not exist',
// 103: 'The requested method does not exist',
// 104: 'The requested version does not support the functionality',
// 105: 'The logged in session does not have permission',
// 106: 'Session timeout',
// 107: 'Session interrupted by duplicate login'
// 400 No such account or incorrect password
// 401 Guest account disabled
// 402 Account disabled
// 403 Wrong password
// 404 Permission denied

@end

static NSString *AUTH_ENDPOINT = @"auth.cgi";
static NSString *AUTH_API = @"SYNO.API.Auth";
static NSString *TASK_ENDPOINT = @"DownloadStation/task.cgi";
static NSString *TASK_API = @"SYNO.DownloadStation.Task";

static NSCharacterSet *QuerySaveCharacters = NULL;

@implementation DSMConnector

- (NSString *)stateDescription {
    switch (self.state) {
        case DSMConnectorOffline:
            return @"Not connected";
        case DSMConnectorReconnecting:
        case DSMConnectorLoggingIn:
            return @"Connecting…";
        case DSMConnectorLoggingOut:
            return @"Disconnecting…";
        case DSMConnectorConnected:
            return [NSString stringWithFormat:@"Connected to %@", self.host];
    }
}

- (id)init {
    if ((self = [super init]) == nil)
        return nil;

    if (QuerySaveCharacters == NULL) {
        QuerySaveCharacters = [[NSCharacterSet characterSetWithCharactersInString:@":/?#[]@!$&’()*+,;="] invertedSet];
    }
    
    _state = DSMConnectorOffline;
    outstanding_requests = [NSMutableSet set];
    logout_completion_handler = NULL;
    
    return self;
}


- (void)connectSecure:(BOOL)secure host:(NSString *)host port:(NSUInteger)port user:(NSString *)user password:(NSString *)password handler:(void (^)(NSError *))handler {
    if (!host || !user) {
        // TODO: include human readable error string
        return handler([NSError errorWithDomain:@"DSMConnector" code:1 userInfo:nil]);
    }
    if (port == 0) {
        port = secure ? 5001 : 5000;
    }
    if (port > 0xffff) {
        // TODO: include human readable error string
        return handler([NSError errorWithDomain:@"DSMConnector" code:1 userInfo:nil]);
    }
    if (!password) {
        password = [self getPasswordforHost:host port:port user:user];
        if (!password) {
            // TODO: include human readable error string
            return handler([NSError errorWithDomain:@"DSMConnector" code:1 userInfo:nil]);
        }
    }


    BOOL changed = NO;
    
    if (secure != _secure) {
        [self willChangeValueForKey:@"secure"];
        _secure = secure;
        [self didChangeValueForKey:@"secure"];
        changed = YES;
    }
    if (host != _host) {
        [self willChangeValueForKey:@"host"];
        _host = host;
        [self didChangeValueForKey:@"host"];
        changed = YES;
    }
    if (port != _port) {
        [self willChangeValueForKey:@"port"];
        _port = port;
        [self didChangeValueForKey:@"port"];
        changed = YES;
    }
    if (user != _user) {
        [self willChangeValueForKey:@"user"];
        _user = user;
        [self didChangeValueForKey:@"user"];
        changed = YES;
    }
    if (password != _password) {
        [self willChangeValueForKey:@"password"];
        _password = password;
        [self didChangeValueForKey:@"password"];
        changed = YES;
    }

    if (!changed) {
        return handler(nil);
    }
    
    if (self.state != DSMConnectorOffline) {
        [self setState:DSMConnectorReconnecting];
        [self logoutImmediately:NO handler:^(NSError *error) {
            if (error) {
                return handler(error);
            }
            [self loginHandler:handler];
        }];
    }
    else {
        [self loginHandler:handler];
    }
}


- (NSString *)getPasswordforHost:(NSString *)host port:(NSUInteger)port user:(NSString *)user {
    const char *c_host = [host UTF8String];
    const char *c_user = [user UTF8String];
    void *c_password;
    UInt32 password_length;
    
    OSStatus status = SecKeychainFindInternetPassword(NULL, (UInt32)strlen(c_host), c_host, 0, NULL, (UInt32)strlen(c_user), c_user, 0, "", port, kSecProtocolTypeHTTPS, kSecAuthenticationTypeAny, &password_length, &c_password, NULL);
    
    if (status != 0)
        return nil;
    
    NSString *password = [[NSString alloc] initWithBytes:c_password length:password_length encoding:NSUTF8StringEncoding];
    
    SecKeychainItemFreeContent(NULL, c_password);
    
    return password;
}


- (NSString *)baseURL {
    return [NSString stringWithFormat:@"%s://%@:%lu/webapi/", self.secure ? "https" : "http", self.host, (unsigned long)self.port];
}


- (NSString *)encodeParameters:(NSDictionary *)parameters {
    NSMutableString *query = [NSMutableString string];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [query appendFormat:@"%s%@=%@", ([query length] > 0 ? "&" : ""), [key stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters], [value stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters]];
    }];

    if (session_id != nil) {
        [query appendFormat:@"%s_sid=%@", ([query length] > 0 ? "&" : ""), [session_id stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters]];
    }
    
    return query;
}


- (void)sendRequestToEndpoint:(NSString *)endpoint withParameters:(NSDictionary *)parameters completionHandler:(void (^)(NSURLResponse *, NSDictionary *, NSError *))handler {
    static NSRegularExpression *hide_password = NULL;
    if (hide_password == NULL) {
        hide_password = [NSRegularExpression regularExpressionWithPattern:@"passwd=[^&]*" options:0 error:NULL];
    }

    NSString *url_string = [NSString stringWithFormat:@"%@%@?%@", [self baseURL], endpoint, [self encodeParameters:parameters]];
    NSURL *url = [[NSURL alloc] initWithString:url_string];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    if (hide_password == NULL) {
        hide_password = [NSRegularExpression regularExpressionWithPattern:@"passwd=[^&]*" options:0 error:NULL];
    }
    NSRange r = { 0, [url_string length] };
    NSString *url_log = [hide_password stringByReplacingMatchesInString:url_string options:0 range:r withTemplate:@"passwd=XXXX"];
    NSLog(@"sending request %@", url_log);
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *body, NSError *error) {
                               [self completedRequest:request];
                               NSDictionary *result = nil;
                               if (body) {
                                   NSLog(@"got result: %@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
                                   result = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
                               }
                               if (result) {
                                   if ([result[@"success"] boolValue] != YES) {
                                       if ([result[@"success"] boolValue] != YES) {
                                           error = [NSError errorWithDomain:@"SynologyWebAPI"
                                                                       code:[result[@"error"][@"code"] integerValue]
                                                                   userInfo:NULL];
                                           // TODO: human readable error (in userInfo?)
                                           NSLog(@"Can't log in: %d", [result[@"error"][@"code"] intValue]);
                                           result = nil;
                                       }
                                   }
                               }
                               handler(response, result, error);
                           }];
}

- (void)completedRequest:(NSURLRequest *)request {
    [outstanding_requests removeObject:request];
    
    if ([outstanding_requests count] == 0 && logout_completion_handler) {
        [self logoutImmediately:YES handler:logout_completion_handler];
        logout_completion_handler = NULL;
    }
}

- (void)setState:(DSMConnectorState)state {
    if (state == _state) {
        return;
    }
    
    [self willChangeValueForKey:@"stateDescription"];
    [self willChangeValueForKey:@"state"];
    _state = state;
    [self didChangeValueForKey:@"state"];
    [self didChangeValueForKey:@"stateDescription"];
}

- (void)loginHandler:(void (^)(NSError *))handler {
    if (self.state != DSMConnectorReconnecting) {
        [self setState:DSMConnectorLoggingIn];
    }
    
    [self sendRequestToEndpoint:AUTH_ENDPOINT
                 withParameters:@{ @"api": AUTH_API, @"method": @"login", @"version": @"2",
                                   @"account": self.user,
                                   @"passwd": self.password,
                                   @"session": @"DSMenu",
                                   @"format": @"sid" }
              completionHandler:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
                  if (error) {
                      [self setState:DSMConnectorOffline];
                      NSLog(@"Can't log in: %@", error);
                  }
                  else {
                      [self setState:DSMConnectorConnected];
                      session_id = result[@"data"][@"sid"];
                      NSLog(@"logged in");
                  }
                  handler(error);
              }];
}

- (void)logoutImmediately:(BOOL)immediately handler:(void (^)(NSError *))handler {
    if (self.state != DSMConnectorReconnecting) {
        [self setState:DSMConnectorLoggingOut];
    }
    if (!immediately && [outstanding_requests count]) {
        logout_completion_handler = handler;
        return;
    }
    
    [self sendRequestToEndpoint:AUTH_ENDPOINT
                 withParameters:@{ @"api": AUTH_API, @"method": @"logout", @"version": @"1",
                                   @"session": @"DSMenu" }
              completionHandler:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
                  // If logout fails, assume connection is unusable and consider disconnected.
                  [self setState:(self.state == DSMConnectorReconnecting ? DSMConnectorLoggingIn : DSMConnectorOffline)];
                  return handler(error);
              }];
    session_id = nil;
}

- (void)createTaskFromURI:(NSString *)URI handler:(void (^)(NSError *))handler {
    switch (self.state) {
        case DSMConnectorOffline:
        case DSMConnectorLoggingOut:
            // TODO: proper error: not connected
            return handler([NSError errorWithDomain:@"DSMConnector" code:1 userInfo:nil]);
            
        case DSMConnectorLoggingIn:
        case DSMConnectorReconnecting:
            // TODO: remember task
            return;
            
        case DSMConnectorConnected:
            [self sendRequestToEndpoint:TASK_ENDPOINT
                         withParameters:@{@"api": TASK_API, @"method": @"create", @"version": @"1",
                                          @"uri": URI }
                      completionHandler:^(NSURLResponse *response, NSDictionary *result, NSError *error) {
                          handler(error);
                      }];
    }
}


- (void)createTaskFromFilename:(NSString *)filename data:(NSData *)data handler:(void (^)(NSError *))handler {
    // TODO: implement
    handler(nil);
}

//@"http://infosphere.foo:5000/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&version=1&method=list&_sid=%@";



@end

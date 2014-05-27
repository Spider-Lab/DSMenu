//
//  DSMConnector.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/15.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMConnector.h"

NSString *DSMConnectorErrorDomain = @"at.spiderlab.DSMenu";

static NSString *DEFAULTS_HOST_KEY = @"DSMHost";
static NSString *DEFAULTS_PORT_KEY = @"DSMPort";
static NSString *DEFAULTS_SECURE_KEY = @"DSMSecure";
static NSString *DEFAULTS_USER_KEY = @"DSMUser";

static NSDictionary *ErrorDescription;

@interface DSMConnectorRequest : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate> {
    NSURLRequest *request;
    NSURLResponse *response;
    NSMutableData *body;
    void (^completion_handler)(NSURLRequest *, NSURLResponse *, NSData *, NSError *);
}

- initWithURLRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *, NSURLResponse *, NSData *, NSError *))completionHandler;

@end

@interface DSMConnector () {
    NSString *session_id;
    
    void (^logout_completion_handler)(NSError *);
    NSMutableSet *outstanding_requests;
}

@end

static NSString *AUTH_ENDPOINT = @"auth.cgi";
static NSString *AUTH_API = @"SYNO.API.Auth";
static NSString *TASK_ENDPOINT = @"DownloadStation/task.cgi";
static NSString *TASK_API = @"SYNO.DownloadStation.Task";

static NSCharacterSet *QuerySaveCharacters = NULL;

@implementation DSMConnector

#pragma mark - Initialization

+ (void)initialize {
    QuerySaveCharacters = [[NSCharacterSet characterSetWithCharactersInString:@":/?#[]@!$&’()*+,;="] invertedSet];
    
    ErrorDescription = @{ @(DSMConnectorNoLoginError): @"No login provided",
                          @(DSMConnectorNoPasswordError): @"No password provided",
                          @(DSMConnectorNotConnectedError): @"Not connected",
                          @(DSMConnectorInvalidReplyError): @"The server sent an invalid reply",
                          
                          @(DSMConnectorUnknownError): @"Unknown error",
                          @(DSMConnectorInvalidParameterError): @"Invalid Parameter",
                          @(DSMConnectorUnknownAPIError): @"The requested API does not exist",
                          @(DSMConnectorUnknownMethodError): @"The requested method does not exist",
                          @(DSMConnectorVersionTooLowError): @"The requested version does not support the functionality",
                          @(DSMConnectorInsuficcientPermissionError): @"The logged in session does not have permission",
                          @(DSMConnectorSessionTimedOutError): @"Session timeout",
                          @(DSMConnectorSessionInterruptedError): @"Session interrupted by duplicate login",
                          
                          @(DSMConnectorIncorrectLoginError): @"No such account or incorrect password",
                          @(DSMConnectorGuestAccountDisabledError): @"Guest account disabled",
                          @(DSMConnectorAccountDisabledError): @"Account disabled",
                          @(DSMConnectorWrongPasswordError): @"Wrong password",
                          @(DSMConnectorPermissionDeniedError): @"Permission denied" };
}


- (id)init {
    if ((self = [super init]) == nil)
        return nil;

    _state = DSMConnectorOffline;
    _secure = YES;
    outstanding_requests = [NSMutableSet set];
    logout_completion_handler = NULL;
    
    return self;
}


#pragma mark - Properties

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


#pragma mark - Login

- (void)restoreLoginHandler:(void (^)(NSError *))handler {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *secure_obj = [defaults objectForKey:DEFAULTS_SECURE_KEY];
    NSString *host = [defaults objectForKey:DEFAULTS_HOST_KEY];
    NSString *port_obj = [defaults objectForKey:DEFAULTS_PORT_KEY];
    NSString *user = [defaults objectForKey:DEFAULTS_USER_KEY];
    
    if (secure_obj == nil || host == nil || port_obj == nil || user == nil) {
        return handler([self errorWithCode:DSMConnectorNoLoginError message:nil]);
    }
    
    NSInteger port = [port_obj integerValue];
    BOOL secure = [secure_obj boolValue];
    
    if (port < 0 || port > 0xffff) {
        return handler([self errorWithCode:DSMConnectorInvalidParameterError message:[NSString stringWithFormat:@"invalid port %@", port_obj]]);
    }

    NSString *password = [self getPasswordforSecure:secure Host:host port:port user:user];
    if (password == nil) {
        return handler([self errorWithCode:DSMConnectorNoPasswordError message:nil]);
    }
    
    [self connectSecure:secure host:host port:(NSUInteger)port user:user password:password saveLogin:NO handler:handler];
}

- (void)connectSecure:(BOOL)secure host:(NSString *)host port:(NSUInteger)port user:(NSString *)user password:(NSString *)password saveLogin:(BOOL)save_login handler:(void (^)(NSError *))handler {
    if (host == nil || user == nil || password == nil) {
        return handler([self errorWithCode:DSMConnectorInvalidParameterError message:nil]);
    }
    
    if (port == 0) {
        port = secure ? 5001 : 5000;
    }
    
    if (port > 0xffff) {
        return handler([self errorWithCode:DSMConnectorInvalidParameterError message:[NSString stringWithFormat:@"invalid port %lu", port]]);
    }

    BOOL changed = NO;
    
    if (secure != _secure) {
        [self willChangeValueForKey:@"secure"];
        _secure = secure;
        [self didChangeValueForKey:@"secure"];
        changed = YES;
    }
    if (![host isEqualToString:_host]) {
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
    if (![user isEqualToString:_user]) {
        [self willChangeValueForKey:@"user"];
        _user = user;
        [self didChangeValueForKey:@"user"];
        changed = YES;
    }
    if (![password isEqualToString:_password]) {
        [self willChangeValueForKey:@"password"];
        _password = password;
        [self didChangeValueForKey:@"password"];
        changed = YES;
    }

    if (!changed) {
        return handler(nil);
    }
    
    void (^completion_handler)(NSError *) = ^void(NSError *error) {
        if (error == nil && save_login) {
            [self saveLogin];
        }
        return handler(error);
    };
    
    if (self.state != DSMConnectorOffline) {
        [self setState:DSMConnectorReconnecting];
        [self logoutImmediately:NO handler:^(NSError *error) {
            // ignore logout errors
            [self loginHandler:completion_handler];
        }];
    }
    else {
        [self loginHandler:completion_handler];
    }
}


- (NSString *)getPasswordforSecure:(BOOL)secure Host:(NSString *)host port:(NSUInteger)port user:(NSString *)user {
    const char *c_host = [host UTF8String];
    const char *c_user = [user UTF8String];
    void *c_password;
    UInt32 password_length;
    
    int protocol = secure ? kSecProtocolTypeHTTPS : kSecProtocolTypeHTTP;

    OSStatus status = SecKeychainFindInternetPassword(NULL, (UInt32)strlen(c_host), c_host, 0, NULL, (UInt32)strlen(c_user), c_user, 0, "", port, protocol, kSecAuthenticationTypeAny, &password_length, &c_password, NULL);
    
    if (status != 0)
        return nil;
    
    NSString *password = [[NSString alloc] initWithBytes:c_password length:password_length encoding:NSUTF8StringEncoding];
    
    SecKeychainItemFreeContent(NULL, c_password);
    
    return password;
}

- (BOOL)saveLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:@(self.secure) forKey:DEFAULTS_SECURE_KEY];
    [defaults setObject:self.host forKey:DEFAULTS_HOST_KEY];
    [defaults setObject:@(self.port) forKey:DEFAULTS_PORT_KEY];
    [defaults setObject:self.user forKey:DEFAULTS_USER_KEY];
    
    return [self savePassword];
}

- (BOOL)savePassword {
    const char *c_host = [self.host UTF8String];
    const char *c_user = [self.user UTF8String];
    const char *c_password = [self.user UTF8String];
    
    int protocol = self.secure ? kSecProtocolTypeHTTPS : kSecProtocolTypeHTTP;
    OSStatus status = SecKeychainAddInternetPassword(NULL, (UInt32)strlen(c_host), c_host, 0, NULL, (UInt32)strlen(c_user), c_user, 0, "", self.port, protocol, kSecAuthenticationTypeDefault, (UInt32)strlen(c_password), c_password, NULL);
    
    return status == 0;
}

#pragma mark - Protocol Helpers

- (NSString *)baseURL {
    return [NSString stringWithFormat:@"%s://%@:%lu/webapi/", self.secure ? "https" : "http", self.host, (unsigned long)self.port];
}

- (NSString *)URLescape:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters];
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

- (NSData *)encodePostWithBoundary:(NSString *)boundary parameters:(NSDictionary *)parameters files:(NSArray *)files {
    NSMutableData *body = [NSMutableData data];
    
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", boundary, [key stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters], [value stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters]] dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    if (session_id != NULL) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"_sid\"\r\n\r\n%@\r\n", boundary, [session_id stringByAddingPercentEncodingWithAllowedCharacters:QuerySaveCharacters]] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *file = obj;
        [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: fomr-data; name=\"%@\"; filename=\"%@\"\nContent-Type: %@\r\n\r\n", boundary, [self URLescape:[file objectForKey:@"parameter"] ], [self URLescape:[file objectForKey:@"filename"]], [file objectForKey:@"content_type"]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[file objectForKey:@"data"]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return body;
}


- (NSString*)MIMEBoundary
{
    static NSString* MIMEBoundary = nil;
    
    if (MIMEBoundary == nil) {
        MIMEBoundary = [[NSString alloc] initWithFormat:@"------DSMenu_%@", [[NSProcessInfo processInfo] globallyUniqueString]];
    }
    
    return MIMEBoundary;
}

- (void)sendRequestToEndpoint:(NSString *)endpoint withParameters:(NSDictionary *)parameters files:(NSArray *)files completionHandler:(void (^)(NSDictionary *, NSError *))handler {
    NSString *url_string = [[self baseURL] stringByAppendingString:endpoint];
    NSURL *url = [[NSURL alloc] initWithString:url_string];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *boundary = [self MIMEBoundary];
    NSData *body = [self encodePostWithBoundary:boundary parameters:parameters files:files];
    
    request.HTTPMethod = @"POST";
    [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
    request.HTTPBody = body;
    
    [self sendRequest:request completionHandler:handler];
}


- (void)sendRequestToEndpoint:(NSString *)endpoint withParameters:(NSDictionary *)parameters completionHandler:(void (^)(NSDictionary *, NSError *))handler {

    NSString *url_string = [NSString stringWithFormat:@"%@%@?%@", [self baseURL], endpoint, [self encodeParameters:parameters]];
    NSURL *url = [[NSURL alloc] initWithString:url_string];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
 
    [self sendRequest:request completionHandler:handler];
}


- (void)sendRequest:(NSURLRequest *)request completionHandler:(void (^)(NSDictionary *, NSError *))handler {
    static NSRegularExpression *hide_password = NULL;
    if (hide_password == NULL) {
        hide_password = [NSRegularExpression regularExpressionWithPattern:@"passwd=[^&]*" options:0 error:NULL];
    }
    
    NSString *url_string = [[request URL] absoluteString];
    NSRange r = { 0, [url_string length] };
    NSString *url_log = [hide_password stringByReplacingMatchesInString:url_string options:0 range:r withTemplate:@"passwd=XXXX"];
    NSLog(@"sending request %@", url_log);
    

    [self beginRequest:request];
    (void)[[DSMConnectorRequest alloc] initWithURLRequest:request completionHandler:^(NSURLRequest *request, NSURLResponse *response, NSData *body, NSError *error) {
        [self completedRequest:request];
        if (error) {
            NSLog(@"got error: %@", error);
            return handler(nil, error);
        }
        if (!body) {
            NSLog(@"got empty result");
            return handler(nil, [self errorWithCode:DSMConnectorInvalidReplyError message:nil]);
        }
        
        NSLog(@"got result: %@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
        NSDictionary *result = nil;
        result = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
        if (!result) {
            return handler(nil, [self errorWithCode:DSMConnectorInvalidReplyError message:nil]);
        }
        
        if ([result[@"success"] boolValue] != YES) {
            if ([result[@"success"] boolValue] != YES) {
                error = [self errorWithCode:[result[@"error"][@"code"] integerValue] message:nil];
                result = nil;
            }
        }
        handler(result, error);
        }];
}


- (void)beginRequest:(NSURLRequest *)request {
    [outstanding_requests addObject:request];
}


- (void)completedRequest:(NSURLRequest *)request {
    [outstanding_requests removeObject:request];
    
    if ([outstanding_requests count] == 0 && logout_completion_handler) {
        [self logoutImmediately:YES handler:logout_completion_handler];
        logout_completion_handler = NULL;
    }
}


#pragma mark - Request Methods

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
              completionHandler:^(NSDictionary *result, NSError *error) {
                  if (error) {
                      [self setState:DSMConnectorOffline];
                      NSLog(@"Can't log in: %@", error);
                  }
                  else {
                      session_id = result[@"data"][@"sid"];
                      NSLog(@"logged in");
                      [self setState:DSMConnectorConnected];
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
              completionHandler:^(NSDictionary *result, NSError *error) {
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
            return handler([self errorWithCode:DSMConnectorNotConnectedError message:nil]);
            
        case DSMConnectorLoggingIn:
        case DSMConnectorReconnecting:
            // TODO: remember task
            return;
            
        case DSMConnectorConnected:
            [self sendRequestToEndpoint:TASK_ENDPOINT
                         withParameters:@{@"api": TASK_API, @"method": @"create", @"version": @"1",
                                          @"uri": URI }
                      completionHandler:^(NSDictionary *result, NSError *error) {
                          handler(error);
                      }];
    }
}


- (void)createTaskFromFilename:(NSString *)filename data:(NSData *)data handler:(void (^)(NSError *))handler {
    switch (self.state) {
        case DSMConnectorOffline:
        case DSMConnectorLoggingOut:
            return handler([self errorWithCode:DSMConnectorNotConnectedError message:nil]);
            
        case DSMConnectorLoggingIn:
        case DSMConnectorReconnecting:
            // TODO: remember task
            return;
            
        case DSMConnectorConnected:
            [self sendRequestToEndpoint:TASK_ENDPOINT
                         withParameters:@{@"api": TASK_API, @"method": @"create", @"version": @"1" }
                                  files:@[@{@"parameter":@"file",
                                            @"content_type": @"application/octet-stream",
                                            @"filename": filename,
                                            @"data": data }]
                      completionHandler:^(NSDictionary *result, NSError *error) {
                          handler(error);
                      }];
    }
}


- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    NSString *description = ErrorDescription[@(code)];
    if (description == nil) {
        description = [NSString stringWithFormat:@"Unknown error %ld", code];
    }
    description = NSLocalizedString(description, description);
    if (message) {
        description = [description stringByAppendingFormat:@": %@", NSLocalizedString(message, message)];
    }
    return [NSError errorWithDomain:DSMConnectorErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey: description }];
}

@end

#pragma mark -

@implementation DSMConnectorRequest

- (id)initWithURLRequest:(NSURLRequest *)_request completionHandler:(void (^)(NSURLRequest *, NSURLResponse *, NSData *, NSError *))completionHandler {
    if ((self = [super init]) == nil) {
        return nil;
    }
    
    request = _request;
    completion_handler = completionHandler;
    response = nil;
    body = nil;
    
    (void)[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    return self;
}


- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSLog(@"validating certificate: error [%@] failureResponse [%@] proposedCredential [%@] protectionSpace [%@]",
          [challenge error], [challenge failureResponse], [challenge proposedCredential], [challenge protectionSpace]);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		// we only trust our own domain
		if ([challenge.protectionSpace.host isEqualToString:[[request URL] host]]) {
			NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
			[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		}
	}
    
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)_response {
    response = _response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (body == nil) {
        body = [data mutableCopy];
    }
    else {
        [body appendData:data];
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    return completion_handler(request, response, body, nil);
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    return completion_handler(request, response, body, error);
}

@end

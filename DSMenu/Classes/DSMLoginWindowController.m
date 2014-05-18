//
//  DSMLoginWindowController.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/17.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMLoginWindowController.h"

@interface DSMLoginWindowController ()

@end

@implementation DSMLoginWindowController

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.window orderOut:nil];
}


- (void)ok:(id)sender {
    [self.connector connectSecure:(self.secure_checkbox.state == NSOnState)
                             host:[self.host_field stringValue]
                             port:[[self.port_field stringValue] integerValue]
                             user:[self.user_field stringValue]
                         password:[self.password_field stringValue]
                        saveLogin:YES
                          handler:^(NSError *erorr) {
        // TODO: handle login error
    }];
    [self.window orderOut:nil];
}


- (void)showLoginWindow:(id)sender {
    if (self.connector.host) {
        [self.host_field setStringValue: self.connector.host];
    }
    if (self.connector.port) {
        [self.port_field setStringValue: [NSString stringWithFormat:@"%lu", self.connector.port]];
    }
    self.secure_checkbox.state = self.connector.secure ? NSOnState : NSOffState;
    if (self.connector.user) {
        [self.user_field setStringValue: self.connector.user];
    }
    if (self.connector.password) {
        [self.password_field setStringValue: self.connector.password];
    }
    
    [self.window makeKeyAndOrderFront:nil];
}

@end

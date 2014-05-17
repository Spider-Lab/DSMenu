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
                          handler:^(NSError *erorr) {
        // TODO: handle login error
    }];
    [self.window orderOut:nil];
}


- (void)showLoginWindow:(id)sender {
    [self.host_field setStringValue: self.connector.host];
    [self.port_field setStringValue: [NSString stringWithFormat:@"%lu", self.connector.port]];
    self.secure_checkbox.state = self.connector.secure ? NSOnState : NSOffState;
    [self.user_field setStringValue: self.connector.user];
    [self.password_field setStringValue: self.connector.password];
    
    [self.window makeKeyAndOrderFront:nil];
}

@end

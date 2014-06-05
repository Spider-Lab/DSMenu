//
//  DSMLoginWindowController.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/17.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMLoginWindowController.h"

#import "DSMAppDelegate.h"

@interface DSMLoginWindowController () {
    DSMConnectorConnectionInfo *connection_info;
}

@end

NSCharacterSet *nonDigits;

@implementation DSMLoginWindowController

+ (void)initialize {
    nonDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
}


#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.window orderOut:nil];
}


- (void)ok:(id)sender {
    //self.connectionInfo.port = [NSNumber numberWithInteger:[self.port_field.stringValue integerValue]];
    [self.connector connectTo:self.connectionInfo
                          handler:^(NSError *error) {
                              if (error) {
                                  DSMAppDelegate *app_delegate = (DSMAppDelegate *)[NSApp delegate];
                                  [app_delegate sendLoginFailureNotificationWithError:error];
                              }
                              else {
                                  [self.connectionInfo saveToUserDefaults];
                              }
                          }];
    [self.window orderOut:nil];
}


- (void)showLoginWindow:(id)sender {
    [self willChangeValueForKey:@"connectionInfo"];
    _connectionInfo = [[DSMConnectorConnectionInfo alloc] initWithInfo:self.connector.connectionInfo];
    [self didChangeValueForKey:@"connectionInfo"];
    //self.port_field.stringValue = [self.connectionInfo.port stringValue];
    [self secureChanged:nil];
    
    [super showWindow:sender];
}

- (void)secureChanged:(id)sender {
    NSString *placeholder = self.secure_checkbox.state == NSOnState ? @"5001" : @"5000";
    [self.port_field.cell setPlaceholderString:placeholder];
}


- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object != self.port_field)
        return;
    
    NSString *newText = [self.port_field stringValue];
    NSString *newDigits = [[newText componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    
    if (![newDigits isEqualToString:newText]) {
        [self.port_field setStringValue:newDigits];
    }
}

@end

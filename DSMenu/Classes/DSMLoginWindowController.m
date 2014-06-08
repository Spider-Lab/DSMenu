//
//  DSMLoginWindowController.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/17.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMLoginWindowController.h"

#import "DSMAppDelegate.h"

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
    [self.window makeFirstResponder:nil];
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


- (void)showWindow:(id)sender {
    [self willChangeValueForKey:@"connectionInfo"];
    _connectionInfo = [[DSMConnectorConnectionInfo alloc] initWithInfo:self.connector.connectionInfo];
    [self didChangeValueForKey:@"connectionInfo"];
    [self secureChanged:nil];
    
    [super showWindow:sender];
}

- (void)secureChanged:(id)sender {
    NSString *placeholder = self.secureCheckBox.state == NSOnState ? @"5001" : @"5000";
    [self.portField.cell setPlaceholderString:placeholder];
}


- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object != self.portField)
        return;
    
    NSString *newText = [self.portField stringValue];
    NSString *newDigits = [[newText componentsSeparatedByCharactersInSet:nonDigits] componentsJoinedByString:@""];
    
    if (![newDigits isEqualToString:newText]) {
        [self.portField setStringValue:newDigits];
    }
}

@end

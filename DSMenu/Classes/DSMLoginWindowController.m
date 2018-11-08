/*
  DSMLoginWindowController.m -- controller for Login window
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

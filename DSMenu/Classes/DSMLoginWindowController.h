//
//  DSMLoginWindowController.h
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/17.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DSMConnector.h"
#import "DSMWindowController.h"

@interface DSMLoginWindowController : DSMWindowController

@property (retain) IBOutlet DSMConnector *connector;
@property (retain) IBOutlet NSTextField *host_field;
@property (retain) IBOutlet NSTextField *port_field;
@property (retain) IBOutlet NSTextField *user_field;
@property (retain) IBOutlet NSTextField *password_field;
@property (retain) IBOutlet NSButton *secure_checkbox;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)secureChanged:(id)sender;
- (IBAction)showLoginWindow:(id)sender;
@end

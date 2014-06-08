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
@property (retain) IBOutlet NSTextField *portField;
@property (retain) IBOutlet NSButton *secureCheckBox;

@property (readonly, retain) DSMConnectorConnectionInfo *connectionInfo;

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)secureChanged:(id)sender;

@end

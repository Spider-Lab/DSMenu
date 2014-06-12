//
//  DSMAboutWindowController.h
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/28.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DSMWindowController.h"

@interface DSMAboutWindowController : DSMWindowController

@property (readwrite, retain) IBOutlet NSTextField *nameField;
@property (readwrite, retain) IBOutlet NSTextField *versionField;
@property (readwrite, retain) IBOutlet NSTextField *copyrightField;

@end

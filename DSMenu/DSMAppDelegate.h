//
//  DSMAppDelegate.h
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/15.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DSMConnector.h"
#import "DSMLoginWindowController.h"

@interface DSMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *status_bar_menu;
@property (assign) IBOutlet DSMLoginWindowController *login_window_controller;
@property (retain) NSStatusItem *status_bar_item;

@property (retain) IBOutlet DSMConnector *connector;

- (IBAction)quit:(id)sender;

@end

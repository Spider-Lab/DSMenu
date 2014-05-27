//
//  DSMWindowController.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/27.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMWindowController.h"

@implementation DSMWindowController

- (void)showWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [super showWindow:sender];
}

@end

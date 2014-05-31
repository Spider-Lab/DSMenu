//
//  DSMAboutWindowController.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/28.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMAboutWindowController.h"

@interface DSMAboutWindowController () {
    id event_monitor;
}

@end
@implementation DSMAboutWindowController

- (void)showWindow:(id)sender {
    if (event_monitor == nil) {
        NSEvent* (^handler)(NSEvent*) = ^(NSEvent *theEvent) {
            if (theEvent.window != self.window) {
                return theEvent;
            }
            
            if (theEvent.keyCode == 53) {
                [self.window orderOut:nil];
                return (NSEvent *)nil;
            }
            
            return theEvent;
        };
        event_monitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:handler];
    }
    
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification{
    [NSEvent removeMonitor:event_monitor];
    event_monitor = nil;
}

@end

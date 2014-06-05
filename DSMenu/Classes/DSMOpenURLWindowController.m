//
//  DSMOpenURLWindowController.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/25.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMOpenURLWindowController.h"
#import "DSMAppDelegate.h"

//@interface DSMOpenURLWindowController ()
//@end

@implementation DSMOpenURLWindowController

- (void)showWindow:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *urls = [pasteboard readObjectsForClasses:@[[NSURL class]] options:nil];
    
    NSString *content = @"";
    for (NSURL *url in urls) {
        if ([url isFileURL] || [url isFileReferenceURL]) {
            continue;
        }
        
        content = [url absoluteString];
        break;
    }
    
    self.urlField.stringValue = content;
    [self.urlField selectText:nil];
    [super showWindow:sender];
}

- (void)cancel:(id)sender {
    [self.window orderOut:nil];
}

- (void)openURL:(id)sender {
    DSMAppDelegate *app_delegate = (DSMAppDelegate *)[NSApp delegate];
    NSString *url = [self.urlField stringValue];
    
    if ([url length] > 0) {
        [app_delegate openURL:url];
    }
    
    [self.window orderOut:nil];
}

@end

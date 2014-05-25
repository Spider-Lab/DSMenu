//
//  DSMAppDelegate.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/15.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMAppDelegate.h"


@implementation DSMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    NSFont *font = self.about_link.font;
    [self.about_link setAllowsEditingTextAttributes: YES];
    [self.about_link setSelectable: YES];
    NSData *html = [[NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%fpx;\"><a href=\"%@\">%@</a></span>", [font fontName], [font pointSize], self.about_link.stringValue, self.about_link.stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:html documentAttributes:nil];
    [self.about_link setAttributedStringValue: string];
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    self.status_bar_item = [bar statusItemWithLength:NSSquareStatusItemLength];
    
    [self.status_bar_item setImage:[NSImage imageNamed:@"Status Bar Icon"]];
    [self.status_bar_item setHighlightMode:YES];
    [self.status_bar_item setMenu:self.status_bar_menu];
    
    [self.connector restoreLoginHandler:^(NSError *error) {
        if (error) {
            if ([error.domain isEqualToString:DSMConnectorErrorDomain] && (error.code == DSMConnectorNoLoginError || error.code == DSMConnectorNoPasswordError)) {
                [self.login_window_controller showLoginWindow:self];
            }
            else {
                [self sendNotificationWithTitle:@"Can't log in" informativeText:[error localizedDescription]];
            }
        }
    }];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    [self openURL:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
}

- (void)openURL:(NSString *)url {
    NSLog(@"got URL: %@", url);
    [NSApp deactivate];
    [self.connector createTaskFromURI:url handler:^(NSError *error) {
        if (error) {
            NSLog(@"can't create downlaod taks from URL %@: %@", url, error);

            [self sendNotificationWithTitle:@"Can't create task" informativeText:[error localizedDescription]];
        }
        else {
            NSLog(@"created download task from URL %@", url);

            [self sendNotificationWithTitle:@"Created task" informativeText:url];
        }
    }];
    
}


- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    [NSApp deactivate];
    return [self openFile:filename];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.connector logoutImmediately:YES handler:^(NSError *error) { }];
}


- (void)sendNotificationWithTitle:(NSString *)title informativeText:(NSString *)informativeText {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = informativeText;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (BOOL)openFile:(NSString *)filename {
    NSLog(@"opening file %@", filename);
    
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:filename];
    
    if (data == nil) {
        NSLog(@"can't read file %@", filename);
        // TODO: send error notification
        return NO;
    }
    
    [self.connector createTaskFromFilename:[filename lastPathComponent] data:data handler:^(NSError *error) {
        if (error) {
            NSLog(@"can't create downlaod taks from file %@: %@", filename, error);
            [self sendNotificationWithTitle:@"Can't create task" informativeText:[error localizedDescription]];
        }
        else {
            NSLog(@"created download task from file %@", filename);
            [self sendNotificationWithTitle:@"Created task" informativeText:[filename lastPathComponent]];
        }
    }];
    
    return YES;
    
}

- (void)quit:(id)sender {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)openFiles:(id)sender {
    NSOpenPanel* open_panel = [NSOpenPanel openPanel];
    
    [open_panel setPrompt:@"Create Task"];
    [open_panel setAllowedFileTypes:@[@"torrent"]];
    
    [open_panel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSFileHandlingPanelOKButton) {
            return;
        }
        
        NSArray* urls = [open_panel URLs];
        
        for (NSURL* url in urls) {
            [self openFile:[url path]];
        }
    }];
}

#pragma mark - NSUserNotificationCenterDelegate methods

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

@end

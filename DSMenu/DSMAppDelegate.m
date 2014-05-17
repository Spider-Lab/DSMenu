//
//  DSMAppDelegate.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/15.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "DSMAppDelegate.h"

static NSString *DEFAULTS_HOST_KEY = @"DSMHost";
static NSString *DEFAULTS_PORT_KEY = @"DSMPort";
static NSString *DEFAULTS_USER_KEY = @"DSMUser";


@implementation DSMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //NSString *host = [defaults objectForKey:DEFAULTS_HOST_KEY];
    //NSInteger port = [[defaults objectForKey:DEFAULTS_PORT_KEY] integerValue];
    
    [self.connector connectSecure:YES host:@"infosphere.foo" port:5001 user:@"dillo" password:nil handler:^(NSError *error) {
        // TODO: handle login failure
    }];
        
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    self.status_bar_item = [bar statusItemWithLength:NSSquareStatusItemLength];
    
    [self.status_bar_item setImage:[NSImage imageNamed:@"Status Bar Icon"]];
    [self.status_bar_item setHighlightMode:YES];
    [self.status_bar_item setMenu:self.status_bar_menu];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSLog(@"got URL: %@", url);
    [self.connector createTaskFromURI:url handler:^(NSError *error) {
        if (error) {
            NSLog(@"can't create downlaod taks from URL %@: %@", url, error);
        }
        else {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Created Task";
            notification.informativeText = [NSString stringWithFormat:@"for URL %@", url];
            notification.soundName = NSUserNotificationDefaultSoundName;
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            NSLog(@"created download task from URL %@", url);
        }
    }];
}


- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSLog(@"opening file %@", filename);
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:filename];
    
    if (data == nil) {
        NSLog(@"can't read file %@", filename);
        return NO;
    }
    
    [self.connector createTaskFromFilename:[filename lastPathComponent] data:data handler:^(NSError *error) {
        if (error) {
            NSLog(@"can't create downlaod taks from file %@: %@", filename, error);
        }
        else {
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Created Task";
            notification.informativeText = [NSString stringWithFormat:@"for file %@", [filename lastPathComponent]];
            notification.soundName = NSUserNotificationDefaultSoundName;
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            NSLog(@"created download task from file %@", filename);
        }
    }];
    
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.connector logoutImmediately:YES handler:^(NSError *error) { }];
}


- (void)quit:(id)sender {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}
@end

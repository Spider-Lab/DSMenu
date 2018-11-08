/*
  DSMAppDelegate.m -- App delegate
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

#import "DSMAppDelegate.h"

@interface DSMAppDelegate () {
    NSMutableArray *pendingFiles;
    NSMutableArray *pendingURLs;
}

@end

#define DSMLoginFailureKey @"DSMLoginFailure"


@implementation DSMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    self.status_bar_item = [bar statusItemWithLength:NSSquareStatusItemLength];
    
    [self.status_bar_item setImage:[NSImage imageNamed:@"Status Bar Icon"]];
    [self.status_bar_item setHighlightMode:YES];
    [self.status_bar_item setMenu:self.status_bar_menu];
    
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    pendingFiles = [NSMutableArray array];
    pendingURLs =[NSMutableArray array];
    
    [self.connector restoreLoginWithHandler:^(NSError *error) {
        if (error) {
            if ([error.domain isEqualToString:DSMConnectorErrorDomain] && (error.code == DSMConnectorNoLoginError || error.code == DSMConnectorNoPasswordError)) {
                [self.login_window_controller showWindow:self];
            }
            else {
                [self sendLoginFailureNotificationWithError:error];
            }
        }
    }];
    
    [self.connector addObserver:self forKeyPath:@"state" options:0 context:NULL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
#if DEBUG
    NSLog(@"handling url %@", [[event paramDescriptorForKeyword:keyDirectObject] stringValue]);
#endif
    [self openURL:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
}

- (void)openURL:(NSString *)url {
#if DEBUG
    NSLog(@"opening URL: %@ (state %@)", url, self.connector.stateDescription);
#endif
    
    if (self.connector.state == DSMConnectorLoggingIn) {
        [pendingURLs addObject:url];
        return;
    }

    [self.connector createTaskFromURI:url handler:^(NSError *error) {
        if (error) {
            NSLog(@"can't create downlaod taks from URL %@: %@", url, error);
            
            [self sendNotificationWithTitle:NSLocalizedString(@"Can't create task", @"Can't create task") informativeText:[error localizedDescription]];
        }
        else {
#if DEBUG
            NSLog(@"created download task from URL %@", url);
#endif
            
            [self sendNotificationWithTitle:NSLocalizedString(@"Created task", @"Created task") informativeText:url];
        }
    }];
}


- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    return [self openFile:filename];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.connector logoutImmediately:YES handler:^(NSError *error) { }];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.connector && [keyPath isEqualToString:@"state"]) {
        switch (self.connector.state) {
            case DSMConnectorConnected: {
                [self.status_bar_item setImage:[NSImage imageNamed:@"Status Bar Icon"]];
#if DEBUG
                NSLog(@"processing pending tasks");
#endif
                [pendingFiles enumerateObjectsUsingBlock:^(NSString *filename, NSUInteger idx, BOOL *stop) {
                    NSLog(@"pending open of file %@", filename);
                    [self openFile:filename];
                }];
                [pendingURLs enumerateObjectsUsingBlock:^(NSString *url, NSUInteger idx, BOOL *stop) {
                    NSLog(@"pending open of url %@", url);
                    [self openURL:url];
                }];
                [pendingFiles removeAllObjects];
                [pendingURLs removeAllObjects];
#if DEBUG
                NSLog(@"done processing pending tasks");
#endif
                break; }
                
            case DSMConnectorOffline:
                [self.status_bar_item setImage:[NSImage imageNamed:@"Status Bar Icon Error"]];
                // TODO: post creation failure notifications?
                [pendingFiles removeAllObjects];
                [pendingURLs removeAllObjects];
                break;
                
            default:
                break;
        }
    }
}

- (void)sendLoginFailureNotificationWithError:(NSError *)error {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = NSLocalizedString(@"Cannot log in", @"Cannot log in");
    notification.informativeText = [NSString stringWithFormat:NSLocalizedString(@"%@\nClick to change connection settings.", @"%@\nClick to change connection settings."), [error localizedDescription]];
    notification.hasActionButton = YES;
    notification.userInfo = @{DSMLoginFailureKey: @(true) };
    notification.actionButtonTitle = NSLocalizedString(@"Connect", @"Connect");
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)sendNotificationWithTitle:(NSString *)title informativeText:(NSString *)informativeText {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = informativeText;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (BOOL)openFile:(NSString *)filename {
#if DEBUG
    NSLog(@"opening file: %@ (state %@)", filename, self.connector.stateDescription);
#endif

    if (self.connector.state == DSMConnectorLoggingIn) {
        [pendingFiles addObject:filename];
        return YES;
    }

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:filename options:0 error:&error];
   
    if (data == nil) {
        NSLog(@"can't read file %@: %@", filename, error);
        [self sendNotificationWithTitle:NSLocalizedString(@"Can't create task", @"Can't create task") informativeText:[error localizedDescription]];
        return NO;
    }
    
    [self.connector createTaskFromFilename:[filename lastPathComponent] data:data handler:^(NSError *error) {
        if (error) {
            NSLog(@"can't create downlaod taks from file %@: %@", filename, error);
            [self sendNotificationWithTitle:NSLocalizedString(@"Can't create task", @"Can't create task") informativeText:[error localizedDescription]];
        }
        else {
#if DEBUG
            NSLog(@"created download task from file %@", filename);
#endif
            [self sendNotificationWithTitle:NSLocalizedString(@"Created task", @"Created task") informativeText:[filename lastPathComponent]];
        }
    }];
    
    return YES;
}

- (void)quit:(id)sender {
    [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
}

- (void)openFiles:(id)sender {
    NSOpenPanel* open_panel = [NSOpenPanel openPanel];
    
    [open_panel setPrompt:NSLocalizedString(@"Create Task", @"Create Task")];
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

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSNumber *isLoginFailure = notification.userInfo[DSMLoginFailureKey];
    if (isLoginFailure && [isLoginFailure boolValue]) {
        [self.login_window_controller showWindow:nil];
    }
}

@end

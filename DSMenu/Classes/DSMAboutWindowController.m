/*
  DSMAboutWindowController.m -- controller for About window
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
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    self.nameField.stringValue = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
    self.versionField.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Version %@", @"Version %@"), [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    self.copyrightField.stringValue = [[mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"] stringByReplacingOccurrencesOfString:@". " withString:@".\n"];;
    
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification{
    [NSEvent removeMonitor:event_monitor];
    event_monitor = nil;
}

@end

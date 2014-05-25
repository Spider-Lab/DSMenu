//
//  DSMOpenURLWindowController.h
//  DSMenu
//
//  Created by Dieter Baron on 2014/05/25.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DSMOpenURLWindowController : NSWindowController

@property (retain, nonatomic) IBOutlet NSTextField *urlField;

-(IBAction)cancel:(id)sender;
-(IBAction)openURL:(id)sender;

@end

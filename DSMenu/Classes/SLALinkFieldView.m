//
//  SLALinkFieldView.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/06/08.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "SLALinkFieldView.h"

@implementation SLALinkFieldView

- (void)resetCursorRects {
    NSRect rect = self.frame;
    
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    [self addCursorRect:rect cursor:[NSCursor pointingHandCursor]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSFont *font = self.font;
    [self setAllowsEditingTextAttributes: YES];
    [self setSelectable: YES];
    NSData *html = [[NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%fpx;\"><a href=\"%@\">%@</a></span>", [font fontName], [font pointSize], self.stringValue, self.stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString* string = [[NSAttributedString alloc] initWithHTML:html documentAttributes:nil];
    [self setAttributedStringValue: string];
}

- (void)setStringValue:(NSString *)string {
    [super setStringValue:string];
}

@end

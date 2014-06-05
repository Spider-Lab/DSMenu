//
//  DSMNumberTransformer.m
//  DSMenu
//
//  Created by Dieter Baron on 2014/06/05.
//  Copyright (c) 2014 Spider Lab. All rights reserved.
//

#import "SLAIntegerTransformer.h"

@implementation SLAIntegerTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}


+ (BOOL)allowsReverseTransformation {
    return YES;
}


- (id)transformedValue:(id)value {
    NSNumber *number = value;
    
    if (value == nil)
        return nil;
    
    return [NSString stringWithFormat:@"%ld", [number integerValue]];
}


- (id)reverseTransformedValue:(id)value {
    NSString *string = value;
    
    if (value == nil)
        return nil;
    
    return [NSNumber numberWithInteger:[string integerValue]];
}

@end

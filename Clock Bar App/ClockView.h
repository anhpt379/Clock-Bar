//
//  ClockView.h
//  Clock Bar
//
//  Created by Jelmer van der Linde on 23/04/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClockView : NSView

@property (nonatomic, strong) NSDate *date;

@property (nonatomic, strong) NSColor *color;

@property (nonatomic) BOOL showSecondHand;

- (void)drawHandAtAngle:(double)angle withRadius:(double)radius atPosition:(NSPoint) center;

- (void)setDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END

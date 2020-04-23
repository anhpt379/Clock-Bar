//
//  ClockView.m
//  Clock Bar
//
//  Created by Jelmer van der Linde on 23/04/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

#import "ClockView.h"
#include <math.h>

@implementation ClockView

@synthesize date = _date;

- (void)setDate:(NSDate *)date {
    if (_date != date) {
        _date = date;
        [self setNeedsDisplay:YES];
    }
}

@synthesize color = _color;

- (void)setColor:(NSColor *)color {
    if (_color != color) {
        _color = color;
        [self setNeedsDisplay:YES];
    }
}

@synthesize showSecondHand = _showSecondHand;

- (void)setShowSecondHand:(BOOL)showSecondHand {
    if (_showSecondHand != showSecondHand) {
        _showSecondHand = showSecondHand;
        [self setNeedsDisplay:YES];
    }
}

- (void)drawHandAtAngle:(double)angle withRadius:(double)radius atPosition:(NSPoint) center {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:center];
    [path relativeLineToPoint:NSMakePoint(cos(angle) * radius, -sin(angle) * radius)];
    [path stroke];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (_date == nil)
        return;
    
    if (_color == nil)
        _color = [NSColor whiteColor];
    
    double radius = 9;
    double hourRadius   = 0.6 * radius;
    double minuteRadius = 1.0 * radius;
    double secondRadius = 1.0 * radius;
    
    NSCalendar *const calendar = [NSCalendar currentCalendar];
    NSDateComponents *const dateComponents = [calendar components:(NSCalendarUnitMinute|
                                                                   NSCalendarUnitHour|
                                                                   NSCalendarUnitSecond|
                                                                   NSCalendarUnitNanosecond)
                                                         fromDate:_date];
    
    double hourAngle   = 2.0 * M_PI * ((dateComponents.hour + dateComponents.minute / 60.0) / 12.0) - 0.5 * M_PI;
    double minuteAngle = 2.0 * M_PI * ((dateComponents.minute + dateComponents.second / 60.0) / 60.0) - 0.5 * M_PI;
    double secondAngle = 2.0 * M_PI * ((dateComponents.second + dateComponents.nanosecond / (double) NSEC_PER_SEC) / 60.0) - 0.5 * M_PI;
    
    NSPoint center = NSMakePoint(NSWidth([self bounds]) / 2,
                                 NSHeight([self bounds]) / 2);
    
    // Get the graphics context that we are currently executing under
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];

    // Save the current graphics context settings
    [gc saveGraphicsState];

    // Set the color in the current graphics context for future draw operations
    [_color setStroke];

    // Create our circle path
    NSRect rect = NSMakeRect(center.x - radius, center.y - radius, 2 * radius, 2 * radius);
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect: rect];

    // Outline and fill the path
    [circlePath stroke];
    [self drawHandAtAngle:hourAngle withRadius:hourRadius atPosition:center];
    [self drawHandAtAngle:minuteAngle withRadius:minuteRadius atPosition:center];
    
    if (_showSecondHand) {
        [[_color blendedColorWithFraction:0.2 ofColor:[NSColor clearColor]] setStroke];
        [self drawHandAtAngle:secondAngle withRadius:secondRadius atPosition:center];
    }

    // Restore the context to what it was before we messed with it
    [gc restoreGraphicsState];
}

-(NSSize)intrinsicContentSize {
    return NSMakeSize(40, 30);
}

@end

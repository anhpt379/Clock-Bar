//
//  ClockView.m
//  Clock Bar
//
//  Created by Jelmer van der Linde on 23/04/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

@import EventKit;
#import "ClockView.h"
#include <math.h>


@interface ClockView ()

- (void)appendArcToPath:(NSBezierPath*)path forEvent:(EKEvent*)event withRadius:(double)radius atPosition:(NSPoint)center;
- (NSBezierPath*)pathForHandAtFraction:(double)fraction withRadius:(double)radius atPosition:(NSPoint)center;

@end

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

@synthesize showEventBackground = _showEventBackground;

- (void)setShowEventBackground:(BOOL)showEventBackground {
    if (_showEventBackground != showEventBackground) {
        _showEventBackground = showEventBackground;
        [self setNeedsDisplay:YES];
    }
}

@synthesize showEventOutline = _showEventOutline;

- (void)setShowEventOutline:(BOOL)showEventOutline {
    if (_showEventOutline != showEventOutline) {
        _showEventOutline = showEventOutline;
        [self setNeedsDisplay:YES];
    }
}

@synthesize events = _events;

double getHourHandFraction(NSDateComponents *dateComponents) {
    return (((dateComponents.hour % 12) + dateComponents.minute / 60.0) / 12.0);
}

double getMinuteHandFraction(NSDateComponents *dateComponents) {
    return ((dateComponents.minute + dateComponents.second / 60.0) / 60.0);
}

double getSecondHandFraction(NSDateComponents *dateComponents) {
    return ((dateComponents.second + dateComponents.nanosecond / (double) NSEC_PER_SEC) / 60.0);
}

- (void)setEvents:(NSArray *)events {
    _events = events;
    [self setNeedsDisplay:YES];
}

- (void) appendArcToPath:(NSBezierPath *)path forEvent:(EKEvent*)event withRadius:(double)radius atPosition:(NSPoint) center {
    NSCalendar *const calendar = [NSCalendar currentCalendar];
    NSDateComponents* const start = [calendar components:(NSCalendarUnitMinute|NSCalendarUnitHour)
                                                fromDate:event.startDate];
    NSDateComponents* const end   = [calendar components:(NSCalendarUnitMinute|NSCalendarUnitHour)
                                                fromDate:event.endDate];
    [path appendBezierPathWithArcWithCenter:center
                                     radius:radius
                                 startAngle:450 - 360 * getHourHandFraction(end)
                                   endAngle:450 - 360 * getHourHandFraction(start)];
}

- (NSBezierPath*)pathForHandAtFraction:(double)fraction withRadius:(double)radius atPosition:(NSPoint) center {
    double rad = 2.0 * M_PI * fraction - 0.5 * M_PI;
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:center];
    [path relativeLineToPoint:NSMakePoint(cos(rad) * radius, -sin(rad) * radius)];
    return path;
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
    
    NSPoint center = NSMakePoint(NSWidth([self bounds]) / 2,
                                 NSHeight([self bounds]) / 2);
    
    // Get the graphics context that we are currently executing under
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];

    // Save the current graphics context settings
    [gc saveGraphicsState];

    NSBezierPath *path;
    
    // Draw event segment backgrounds
    if (_showEventBackground && _events != nil) {
        for (EKEvent *event in _events) {
            [event.calendar.color setFill];
            [[event.calendar.color blendedColorWithFraction:0.2 ofColor:[NSColor clearColor]] setFill];
            
            path = [NSBezierPath bezierPath];
            [path moveToPoint:center];
            [self appendArcToPath:path forEvent:event withRadius:radius atPosition:center];
            [path fill];
        }
    }
    
    // Draw clock outline
    [_color setStroke];
    NSRect rect = NSMakeRect(center.x - radius, center.y - radius, 2 * radius, 2 * radius);
    path = [NSBezierPath bezierPath];
    [path appendBezierPathWithOvalInRect: rect];
    [path stroke];
    
    // Draw event segment outlines
    if (_showEventOutline && _events != nil) {
        for (EKEvent *event in _events) {
            [event.calendar.color setStroke];
            path = [NSBezierPath bezierPath];
            [self appendArcToPath:path forEvent:event withRadius:radius atPosition:center];
            [path stroke];
        }
    }
    
    // Draw clock hands
    [_color setStroke];
    [[self pathForHandAtFraction:getHourHandFraction(dateComponents) withRadius:hourRadius atPosition:center] stroke];
    [[self pathForHandAtFraction:getMinuteHandFraction(dateComponents) withRadius:minuteRadius atPosition:center] stroke];
    
    if (_showSecondHand) {
        [[_color blendedColorWithFraction:0.2 ofColor:[NSColor clearColor]] setStroke];
        [[self pathForHandAtFraction:getSecondHandFraction(dateComponents) withRadius:secondRadius atPosition:center] stroke];
    }

    // Restore the context to what it was before we messed with it
    [gc restoreGraphicsState];
}

-(NSSize)intrinsicContentSize {
    return NSMakeSize(40, 30);
}

@end

//
//  ScrubberEventItemView.m
//  Clock Bar
//
//  Created by Jelmer van der Linde on 30/04/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

#import "ScrubberEventItemView.h"

@implementation ScrubberEventItemView

@synthesize event = _event;

- (void)setEvent:(EKEvent *)event {
    _event = event;
    self.title = event.title;
    self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSGraphicsContext* gc = [NSGraphicsContext currentContext];
    [gc saveGraphicsState];
    
    // Determine how much of this event has already passed
    CGFloat progress = MAX(0.0, MIN(1.0, (CGFloat) [[NSDate date] timeIntervalSinceDate:_event.startDate] / [_event.endDate timeIntervalSinceDate:_event.startDate]));
    
    // Split the item bounds into a passed and remaining rect
    NSRect passed, remaining;
    NSDivideRect(self.bounds, &passed, &remaining, progress * CGRectGetWidth(self.bounds), NSMinXEdge);
    
    // Colour those two sections separately
    [[_event.calendar.color blendedColorWithFraction:0.2 ofColor:[NSColor clearColor]] setFill];
    [[NSBezierPath bezierPathWithRect:remaining] fill];
    
    [_event.calendar.color setFill];
    [[NSBezierPath bezierPathWithRect:passed] fill];
    
    [gc restoreGraphicsState];
    
    // Do the text thing
    [super drawRect:dirtyRect];
}

@end

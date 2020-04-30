//
//  ScrubberEventItemView.h
//  Clock Bar
//
//  Created by Jelmer van der Linde on 30/04/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

@import Cocoa;
@import EventKit;

NS_ASSUME_NONNULL_BEGIN

@interface ScrubberEventItemView : NSScrubberTextItemView

@property (nonatomic, strong) EKEvent* event;

@end

NS_ASSUME_NONNULL_END

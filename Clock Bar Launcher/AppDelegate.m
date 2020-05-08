//
//  AppDelegate.m
//  Clock Bar Launcher
//
//  Created by Jelmer van der Linde on 08/05/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *path = [[[[[[NSBundle mainBundle] bundlePath]
                        stringByDeletingLastPathComponent]
                        stringByDeletingLastPathComponent]
                        stringByDeletingLastPathComponent]
                        stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] launchApplication:path];
    [NSApp terminate:nil];
}

@end

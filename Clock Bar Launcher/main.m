//
//  main.m
//  Clock Bar Launcher
//
//  Created by Jelmer van der Linde on 08/05/2020.
//  Copyright © 2020 Nihalsharma. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];

        AppDelegate *appDelegate = [[AppDelegate alloc] init];

        [application setDelegate:appDelegate];
        [application run];

        // Setup code that might create autoreleased objects goes here.
    }
    return EXIT_SUCCESS;
}

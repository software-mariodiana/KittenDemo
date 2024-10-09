//
// MDXDeviceNotch.m
//
// ISC License
//
// Copyright (c) 2024, Mario Diana
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

// https://github.com/software-mariodiana/MDXDeviceNotch

#import "MDXDeviceNotch.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MDXDeviceNotchState) {
    MDXDeviceNotchStateUndetermined = -1,
    MDXDeviceNotchStateFalse = 0,
    MDXDeviceNotchStateTrue = 1
};

static MDXDeviceNotchState MDXDeviceNotchValue = MDXDeviceNotchStateUndetermined;

#pragma mark - Private function

UIWindow* MDXKeyWindow(void)
{
    // Apple made things more difficult with this UIScene stuff.
    NSArray* scenes = [[[UIApplication sharedApplication] connectedScenes] allObjects];
    NSMutableArray* windows = [NSMutableArray array];
    
    for (id aScene in scenes) {
        // "Typically, UIKit creates a UIWindowScene object instead of a UIScene object..."
        if ([aScene respondsToSelector:@selector(windows)]) {
            for (id aWindow in [aScene windows]) {
                [windows addObject:aWindow];
            }
        }
    }
    
    NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary* bindings) {
        return [obj isKeyWindow];
    }];
    
    // Reportedly, using firstObject leads to inconsistent results.
    UIWindow* keyWindow = [[windows filteredArrayUsingPredicate:filter] lastObject];
    
    if (!keyWindow) {
        NSLog(@"WARNING (MDXDeviceNotch): Unable to determine key window!");
    }
    
    return keyWindow;
}

#pragma mark - Public function

BOOL MDXHasDeviceNotch(void)
{
    // This never changes, so we need do it only once if we're successful.
    if (MDXDeviceNotchValue == MDXDeviceNotchStateUndetermined) {
        // iPads do not have a device notch.
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
            MDXDeviceNotchValue = MDXDeviceNotchStateFalse;
            return MDXDeviceNotchStateFalse;
        }
        
        UIWindow* window = MDXKeyWindow();
        
        if (!window) {
            NSLog(
                  @"WARNING (MDXDeviceNotch): Unable to determine presence of device notch."
                  " Presence of device notch can be detected only after layout of key window."
                  " This is a programmer error!"
                  " Returning: NO for presence of device notch."
                  );
            
            // Assuming NO should result in a graceful fail.
            return NO;
        }
        
        MDXDeviceNotchValue =
            [window safeAreaInsets].bottom > 0.0 ? MDXDeviceNotchStateTrue : MDXDeviceNotchStateFalse;
    }
    
    return MDXDeviceNotchValue == MDXDeviceNotchStateTrue;
}

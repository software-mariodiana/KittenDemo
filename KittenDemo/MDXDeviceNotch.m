//
// MDXDeviceNotch.m
//
// BSD 3-Clause License
//
// Copyright (c) 2024, Mario Diana
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// 3. Neither the name of Mario Diana nor the names of its contributors may be
//    used to endorse or promote products derived from this software without
//    specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

#import "MDXDeviceNotch.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MDXDeviceNotchState) {
    MDXDeviceNotchStateUndetermined = -1,
    MDXDeviceNotchStateFalse = 0,
    MDXDeviceNotchStateTrue = 1
};


@interface MDXDeviceNotch : NSObject
@property (nonatomic, assign) MDXDeviceNotchState deviceState;
+ (instancetype)sharedInstance;
- (BOOL)hasDeviceNotch;
@end

@implementation MDXDeviceNotch

+ (instancetype)sharedInstance
{
    static MDXDeviceNotch* sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initSharedInstance];
    });
    
    return sharedInstance;
}


- (instancetype)initSharedInstance
{
    self = [super init];
    
    if (self) {
        _deviceState = MDXDeviceNotchStateUndetermined;
    }
    
    return self;
}


- (UIWindow *)keyWindow
{
    // Apple made things more difficult with this UIScene stuff.
    NSArray* scenes = [[[UIApplication sharedApplication] connectedScenes] allObjects];
    NSMutableArray* windows = [NSMutableArray array];
    
    for (id aScene in scenes) {
        for (id aWindow in [aScene windows]) {
            [windows addObject:aWindow];
        }
    }
    
    NSPredicate* filter = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary* bindings) {
        return [obj isKeyWindow];
    }];
    
    // Reportedly, using firstObject leads to inconsistent results.
    return [[windows filteredArrayUsingPredicate:filter] lastObject];
}


- (BOOL)hasDeviceNotch
{
    // This never changes, so we need do it only once.
    if ([self deviceState] == MDXDeviceNotchStateUndetermined) {
        UIWindow* window = [self keyWindow];
        self.deviceState =
            [window safeAreaInsets].bottom > 0.0 ? MDXDeviceNotchStateTrue : MDXDeviceNotchStateFalse;
    }
    
    return [self deviceState] == MDXDeviceNotchStateTrue;
}

@end

#pragma mark - Public functions

BOOL MDXHasDeviceNotch(void)
{
    return [[MDXDeviceNotch sharedInstance] hasDeviceNotch];
}


BOOL MDXHasHomeButton(void)
{
    return !MDXHasDeviceNotch();
}

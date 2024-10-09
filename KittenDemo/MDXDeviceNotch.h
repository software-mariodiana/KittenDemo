//
// MDXDeviceNotch.h
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

#import <Foundation/Foundation.h>

/**
 * Return YES if iOS device has a notch; NO, if it does not.
 *
 * This function detects whether the current iOS device has a notch, such as the one
 * found on iPhone X models and later. It determines this by inspecting the key window's
 * safe area insets, specifically the bottom inset, which is larger on devices with a notch.
 *
 * IMPORTANT: This function relies on the presence of the application's key window to
 * perform its calculations. Therefore, it should not be called until the application's
 * key window has been mounted, as running this function too early in the application's
 * lifecycle (e.g., before the root view controller's view has been laid out) will result
 * in an inability to determine whether the device has a notch. If called too early,
 * a warning will be logged, and the result will not be meaningful.
 *
 * To ensure the function is called at the appropriate time, it is recommended to
 * initialize it in the root view controller, inside the `viewWillLayoutSubviews`
 * method. This guarantees that the view hierarchy has been properly set up and
 * the key window has been mounted. For example:
 *
 * @code
 * - (void)viewWillLayoutSubviews
 * {
 *     static dispatch_once_t onceToken;
 *     dispatch_once(&onceToken, ^{
 *         MDXHasDeviceNotch();
 *     });
 * }
 * @endcode
 *
 * This ensures that the function is only called once during the app's lifecycle
 * and returns a correct and reliable result thereafter, as the presence of a
 * device notch or lack thereof will never change after initialization.
 *
 * @return YES if the current iOS device has a notch, NO otherwise.
 */
BOOL MDXHasDeviceNotch(void);

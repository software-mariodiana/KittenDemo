//
//  KittenStore.h
//  KittenDemo
//
//  Created by Mario Diana on 7/31/24.
//

#import "KittenStoring.h"

@interface KittenHTTPStore : NSObject <KittenStoring>
// Use CreateKittenStore factory function.
- (instancetype)init __attribute__((unavailable("not available")));
@end

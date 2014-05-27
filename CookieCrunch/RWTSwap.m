//
//  RWTSwap.m
//  CookieCrunch
//
//  Created by Yi Zeng on 24/05/2014.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import "RWTSwap.h"
#import "RWTCookie.h"

@implementation RWTSwap

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.cookieA, self.cookieB];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[RWTSwap class]]) return NO;
    
    RWTSwap *other = (RWTSwap *)object;
    
    return (other.cookieA == self.cookieA && other.cookieB == self.cookieB) ||
            (other.cookieB == self.cookieA && other.cookieA == self.cookieB);
}

- (NSUInteger)hash {
    return [self.cookieA hash] ^ [self.cookieB hash];
}
@end

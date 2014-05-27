//
//  RWTChain.m
//  CookieCrunch
//
//  Created by Yi Zeng on 24/05/2014.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import "RWTChain.h"

@implementation RWTChain {
    NSMutableArray *_cookies;
}

- (void)addCookie:(RWTCookie *)cookie
{
    if (_cookies == nil) {
        _cookies = [NSMutableArray array];
    }
    
    [_cookies addObject:cookie];
}

- (NSArray *)cookies {
    return _cookies;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type: %ld cookies:%@", (long)self.chainType, self.cookies];
}

@end

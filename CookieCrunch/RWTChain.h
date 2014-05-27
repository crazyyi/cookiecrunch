//
//  RWTChain.h
//  CookieCrunch
//
//  Created by Yi Zeng on 24/05/2014.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RWTCookie;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainTypeHorizontal,
    ChainTypeVertical,
};

@interface RWTChain : NSObject

@property (strong, nonatomic, readonly) NSArray *cookies;
@property (assign, nonatomic) ChainType chainType;

- (void)addCookie:(RWTCookie *)cookie;

@end

//
//  RWTLevel.h
//  CookieCrunch
//
//  Created by Yi Zeng on 5/22/14.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWTCookie.h"
#import "RWTTile.h"
#import "RWTSwap.h"
#import "RWTChain.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface RWTLevel : NSObject

@property (assign, nonatomic) NSUInteger targetScore;
@property (assign, nonatomic) NSUInteger maximumMoves;

- (NSArray *)topUpCookies;
- (NSSet *)shuffle;
- (NSArray *)fillHoles;
- (RWTCookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row;
- (void)detectPossibleSwaps;
- (instancetype)initWithFile:(NSString *)filename;
- (RWTTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row;
- (void)performSwap:(RWTSwap *)swap;
- (BOOL)isPossibleSwap:(RWTSwap *)swap;
- (NSSet *)removeMatches;
- (void)resetComboMultiplier;

@end

//
//  RWTMyScene.h
//  CookieCrunch
//

//  Copyright (c) 2014 afun. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
@class RWTLevel;
@class RWTSwap;

@interface RWTMyScene : SKScene

@property (nonatomic, strong) RWTLevel *level;
@property (copy, nonatomic) void (^swipeHandler)(RWTSwap *swap);

- (void)addSpriteForCookies:(NSSet *)cookies;
- (void)addTiles;
- (void)animateSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateInvalidSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion;

@end

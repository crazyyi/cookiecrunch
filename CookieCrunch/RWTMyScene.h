//
//  RWTMyScene.h
//  CookieCrunch
//

//  Copyright (c) 2014 afun. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
@class RWTLevel;

@interface RWTMyScene : SKScene

@property (nonatomic, strong) RWTLevel *level;

- (void)addSpriteForCookies:(NSSet *)cookies;

@end

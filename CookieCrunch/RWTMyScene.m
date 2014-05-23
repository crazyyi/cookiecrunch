//
//  RWTMyScene.m
//  CookieCrunch
//
//  Created by Yi Zeng on 5/22/14.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import "RWTMyScene.h"
#import "RWTCookie.h"
#import "RWTLevel.h"


static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface RWTMyScene()
{
    
}

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *cookiesLayer;
@property (strong, nonatomic) SKNode *tilesLayer;
@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;

@end

@implementation RWTMyScene

- (id)initWithSize:(CGSize)size {
    if ((self = [super initWithSize:size])) {
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        _gameLayer = [SKNode node];
        [self addChild:_gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        DDLogVerbose(@"Layer position: x = %f, y = %f", layerPosition.x, layerPosition.y);
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        _cookiesLayer = [SKNode node];
        _cookiesLayer.position = layerPosition;
        
        [_gameLayer addChild:_cookiesLayer];
    }
    return self;
}

- (void)addSpriteForCookies:(NSSet *)cookies
{
    for (RWTCookie *cookie in cookies) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
        NSLog(@"Sprite = %@", sprite.debugDescription);
        sprite.position = [self pointForColumn:cookie.column row:cookie.row];
        [self.cookiesLayer addChild:sprite];
        cookie.sprite = sprite;
    }
}

- (void)addTiles
{
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"Tile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row
{
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end

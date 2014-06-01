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
#import "RWTSwap.h"

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
@property (strong, nonatomic) SKSpriteNode *selectionSprite;
@property (strong, nonatomic) SKAction *swapSound;
@property (strong, nonatomic) SKAction *invalidSwapSound;
@property (strong, nonatomic) SKAction *matchSound;
@property (strong, nonatomic) SKAction *fallingCookieSound;
@property (strong, nonatomic) SKAction *addCookieSound;
@property (strong, nonatomic) SKCropNode *cropLayer;
@property (strong, nonatomic) SKNode *maskLayer;

@end

@implementation RWTMyScene

- (id)initWithSize:(CGSize)size {
    if ((self = [super initWithSize:size])) {
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        _gameLayer = [SKNode node];
        self.gameLayer.hidden = YES;
        [self addChild:_gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        DDLogVerbose(@"Layer position: x = %f, y = %f", layerPosition.x, layerPosition.y);
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        self.cropLayer = [SKCropNode node];
        [self.gameLayer addChild:self.cropLayer];
        
        self.maskLayer = [SKNode node];
        self.maskLayer.position = layerPosition;
        self.cropLayer.maskNode = self.maskLayer;
        
        _cookiesLayer = [SKNode node];
        _cookiesLayer.position = layerPosition;
        
        [_cropLayer addChild:_cookiesLayer];
        
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        self.selectionSprite = [SKSpriteNode node];
        
        [self preloadResources];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        RWTCookie *cookie = [self.level cookieAtColumn:column row:row];
        if (cookie != nil) {
            [self showSelectionIndicatorForCookie:cookie];
            self.swipeFromColumn = column;
            self.swipeFromRow = row;
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.swipeFromColumn == NSNotFound) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {            // swipe left
            horzDelta = -1;
        } else if (column > self.swipeFromColumn) {     // swipe right
            horzDelta = 1;
        } else if (row < self.swipeFromRow) {           // swipe down
            vertDelta = -1;
        } else if (row > self.swipeFromRow) {           // swipe up
            vertDelta = 1;
        }
        
        
        if (horzDelta != 0 || vertDelta != 0) {
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            [self hideSelectionIndicator];
            self.swipeFromColumn = NSNotFound;
        }
        
    }
}

- (void)trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)vertDelta
{
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    if (toColumn < 0 || toColumn >= NumColumns) return;
    if (toRow < 0 || toRow >= NumRows) {
        return;
    }
    
    RWTCookie *toCookie = [self.level cookieAtColumn:toColumn row:toRow];
    if (toCookie == nil) {
        return;
    }
    
    RWTCookie *fromCookie = [self.level cookieAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    if (self.swipeHandler != nil) {
        RWTSwap *swap = [[RWTSwap alloc] init];
        swap.cookieA = fromCookie;
        swap.cookieB = toCookie;
        
        self.swipeHandler(swap);
    }
}

- (void)animateSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion {
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.cookieB.sprite runAction:moveB];
    
    [self runAction:self.swapSound];
}

- (void)animateInvalidSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion {
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.cookieB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
    
    [self runAction:self.invalidSwapSound];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.selectionSprite.parent != nil && self.swipeFromColumn != NSNotFound) {
        [self hideSelectionIndicator];
    }
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row
{
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // Is this a valid location within the cookies layer? If yes,
    // calculate the corresponding row and column numbers.
    if (point.x >= 0 && point.x < NumColumns*TileWidth &&
        point.y >= 0 && point.y < NumRows*TileHeight) {
        
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
        
    } else {
        *column = NSNotFound;  // invalid location
        *row = NSNotFound;
        return NO;
    }
}
- (void)addSpriteForCookies:(NSSet *)cookies
{
    for (RWTCookie *cookie in cookies) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
        NSLog(@"Sprite = %@", sprite.debugDescription);
        sprite.position = [self pointForColumn:cookie.column row:cookie.row];
        [self.cookiesLayer addChild:sprite];
        cookie.sprite = sprite;
        
        cookie.sprite.alpha = 0;
        cookie.sprite.xScale = cookie.sprite.yScale = 0.5;
        [cookie.sprite runAction:[SKAction sequence:@[
                        [SKAction waitForDuration:0.25 withRange:0.5],
                        [SKAction group:@[
                            [SKAction fadeInWithDuration:0.25],
                            [SKAction scaleTo:1.0 duration:0.25]
                        ]]]]];
    }
}

- (void)addTiles
{
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaskTile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.maskLayer addChild:tileNode];
            }
        }
    }
    
    for (NSInteger row = 0; row <= NumRows; row++) {
        for (NSInteger column = 0; column <= NumColumns; column++) {
            BOOL topLeft = (column > 0) && (row < NumRows)
                                        && [self.level tileAtColumn:column - 1 row:row];
            BOOL bottomLeft = (column > 0) && (row > 0)
                                        && [self.level tileAtColumn:column - 1 row:row - 1];
            
            BOOL topRight = (column < NumColumns) && (row < NumRows)
                                        && [self.level tileAtColumn:column row:row];
            BOOL bottomRight = (column < NumColumns) && (row > 0)
                                        && [self.level tileAtColumn:column row:row - 1];
            
            
            // The tiles are named from 0 to 15, according to the bitmask that is
            // made by combining these four values.
            NSUInteger value = topLeft | topRight << 1 | bottomLeft << 2 | bottomRight << 3;
            
            // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
            if (value != 0 && value != 6 && value != 9) {
                NSString *name = [NSString stringWithFormat:@"Tile_%lu", (long)value];
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:name];
                CGPoint point = [self pointForColumn:column row:row];
                point.x -= TileWidth/2;
                point.y -= TileHeight/2;
                tileNode.position = point;
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row
{
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

- (void)showSelectionIndicatorForCookie:(RWTCookie *)cookie
{
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    SKTexture *texture = [SKTexture textureWithImageNamed:[cookie highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    [cookie.sprite addChild:self.selectionSprite];
    self.selectionSprite.alpha = 1.0;
}

- (void)hideSelectionIndicator {
    [self.selectionSprite runAction:[SKAction sequence:@[
                                                        [SKAction fadeOutWithDuration:0.3],
                                                        [SKAction removeFromParent]]]];
}

- (void)preloadResources {
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingCookieSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addCookieSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion {
    for (RWTChain *chain in chains) {
        // Add this line:
        [self animateScoreForChain:chain];
        for (RWTCookie *cookie in chain.cookies) {
            if (cookie.sprite != nil) {
                SKAction *action = [SKAction scaleTo:0.1 duration:0.3];
                action.timingMode = SKActionTimingEaseInEaseOut;
                [cookie.sprite runAction:[SKAction sequence:@[action, [SKAction removeFromParent]]]];
                
                cookie.sprite = nil;
            }
        }
    }
    
    [self runAction:self.matchSound];
    
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.3],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion
{
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        [array enumerateObjectsUsingBlock:^(RWTCookie *cookie, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            
            NSTimeInterval delay = 0.05 + 0.15 * idx;
            
            NSTimeInterval duration = ((cookie.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            longestDuration = MAX(longestDuration, duration + delay);
            
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            
            moveAction.timingMode = SKActionTimingEaseOut;
            
            [cookie.sprite runAction:[SKAction sequence:@[
                        [SKAction waitForDuration:delay],
                        [SKAction group:@[moveAction, self.fallingCookieSound]]]]];
        }];
    }
    
    [self runAction:[SKAction sequence:@[
                [SKAction waitForDuration:longestDuration],
                [SKAction runBlock:completion]]]];
}

- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion
{
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        NSInteger startRow = ((RWTCookie *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(RWTCookie *cookie, NSUInteger idx, BOOL *stop) {
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
            sprite.position = [self pointForColumn:cookie.column row:startRow];
            [self.cookiesLayer addChild:sprite];
            cookie.sprite = sprite;
            
            NSTimeInterval delay = 0.1 + 0.2 * ([array count] - idx - 1);
            
            NSTimeInterval duration = (startRow - cookie.row) * 0.1;
            
            longestDuration = MAX(longestDuration, duration + delay);
            
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            
            cookie.sprite.alpha = 0;
            [cookie.sprite runAction:[SKAction sequence:@[
                        [SKAction waitForDuration:delay],
                        [SKAction group:@[
                            [SKAction fadeInWithDuration:0.05], moveAction, self.addCookieSound]]]]];
        }];
    }
    
    [self runAction:[SKAction sequence:@[
                        [SKAction waitForDuration:longestDuration],
                        [SKAction runBlock:completion]
                        ]]];
}

- (void)animateScoreForChain:(RWTChain *)chain {
    // Figure out what the midpoint of the chain is
    RWTCookie *firstCookie = [chain.cookies firstObject];
    RWTCookie *lastCookie = [chain.cookies lastObject];
    CGPoint centerPosition = CGPointMake(
                        (firstCookie.sprite.position.x + lastCookie.sprite.position.x)/2,
                                         (lastCookie.sprite.position.y + lastCookie.sprite.position.y)/2 - 8);
    
    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.cookiesLayer addChild:scoreLabel];
    
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[
                                               moveAction,
                                               [SKAction removeFromParent]
                                               ]]];
}

- (void)animateGameOver {
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

- (void)animateBeginGame {
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

- (void)removeAllCookieSprites {
    [self.cookiesLayer removeAllChildren];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end

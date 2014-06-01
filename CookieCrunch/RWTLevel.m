//
//  RWTLevel.m
//  CookieCrunch
//
//  Created by Yi Zeng on 5/22/14.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import "RWTLevel.h"

@interface RWTLevel()

@property (strong, nonatomic) NSSet *possibleSwaps;
@property (assign, nonatomic) NSUInteger comboMultiplier;

@end
@implementation RWTLevel {
    RWTCookie *_cookies[NumColumns][NumRows];
    RWTTile *_tiles[NumColumns][NumRows];
}


- (instancetype)initWithFile:(NSString *)filename {
    self = [super init];
    
    if (self != nil) {
        NSDictionary *dictionary = [self loadJSON:filename];
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            // Loop through the rows
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                // Note: In Sprite Kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[RWTTile alloc] init];
                }
            }];
        }];
        
        self.targetScore = [dictionary[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionary[@"moves"] unsignedIntegerValue];
    }
    
    return self;
}

- (NSSet *)shuffle
{
    NSSet *set;
    do {
        set = [self createInitialCookies];
        [self detectPossibleSwaps];
        DDLogVerbose(@"possible swaps: %@ ", self.possibleSwaps);
    } while ([self.possibleSwaps count] == 0);
    
    return set;
}

- (NSSet *)createInitialCookies
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if (_tiles[column][row] != nil) {
                NSUInteger cookieType;
                do {
                    cookieType = arc4random_uniform(NumCookieTypes) + 1;
                }
                while ((column >= 2 &&
                        _cookies[column - 1][row].cookieType == cookieType &&
                        _cookies[column - 2][row].cookieType == cookieType)
                       ||
                       (row >= 2 &&
                        _cookies[column][row - 1].cookieType == cookieType &&
                        _cookies[column][row - 2].cookieType == cookieType));
                
                RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                [set addObject:cookie];
            }
            
        }
    }
    
    return set;
}

- (BOOL)hasChainAtColumn:(NSInteger)column row:(NSInteger)row {
    NSUInteger cookieType = _cookies[column][row].cookieType;
    
    NSUInteger horzLength = 1;
    for (NSInteger i = column - 1; i>=0 && _cookies[i][row].cookieType == cookieType; i--, horzLength++);
    for (NSInteger i = column + 1; i< NumColumns && _cookies[i][row].cookieType == cookieType; i++, horzLength++);
    
    if (horzLength >= 3) return YES;
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row - 1; i >= 0 && _cookies[column][i].cookieType == cookieType; i--, vertLength++) ;
    for (NSInteger i = row + 1; i < NumRows && _cookies[column][i].cookieType == cookieType; i++, vertLength++);
    
    return (vertLength >= 3);
}

- (void)detectPossibleSwaps
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            RWTCookie *cookie = _cookies[column][row];
            if (cookie != nil) {
                if (column < NumColumns - 1) {
                    RWTCookie *other = _cookies[column + 1][row];
                    if (other != nil) {
                        _cookies[column][row] = other;
                        _cookies[column + 1][row] = cookie;
                        
                        if ([self hasChainAtColumn:column + 1 row:row] ||
                            [self hasChainAtColumn:column row:row]) {
                            RWTSwap *swap = [[RWTSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        _cookies[column][row] = cookie;
                        _cookies[column + 1][row] = other;
                    }
                }
                
                if (row < NumRows - 1) {
                    RWTCookie *other = _cookies[column][row + 1];
                    if (other != nil) {
                        _cookies[column][row] = other;
                        _cookies[column][row + 1] = cookie;
                        
                        if ([self hasChainAtColumn:column row:row + 1] ||
                            [self hasChainAtColumn:column row:row]) {
                            RWTSwap *swap = [[RWTSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        _cookies[column][row] = cookie;
                        _cookies[column][row + 1] = other;
                    }
                }
            }
        }
    }
    
    self.possibleSwaps = set;
}

- (BOOL)isPossibleSwap:(RWTSwap *)swap
{
    return [self.possibleSwaps containsObject:swap];
}

- (NSDictionary *)loadJSON:(NSString *)filename {
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        DDLogVerbose(@"Could not find level file: %@", filename);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        DDLogVerbose(@"Could not load level file: %@, error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        DDLogVerbose(@"Level file '%@' is not valid JSON: %@", filename, error.localizedDescription);
    }
    
    return dictionary;
}

- (RWTTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row
{
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

- (RWTCookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _cookies[column][row];
}

- (RWTCookie *)createCookieAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)cookieType {
    RWTCookie *cookie = [[RWTCookie alloc] init];
    cookie.cookieType = cookieType;
    cookie.column = column;
    cookie.row = row;
    _cookies[column][row] = cookie;
    return cookie;
}

- (NSSet *)detectHorizontalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column + 1][row].cookieType == matchType &&
                    _cookies[column + 2][row].cookieType == matchType) {
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    
                    do {
                        [chain addCookie:_cookies[column][row]];
                        column +=1;
                    } while (column < NumColumns && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            column += 1;
        }
    }
    
    return set;
}

- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column][row + 1].cookieType == matchType &&
                    _cookies[column][row + 2].cookieType == matchType) {
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    
                    do {
                        [chain addCookie:_cookies[column][row]];
                        row += 1;
                    } while (row < NumRows && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            row += 1;
        }
    }
    
    return set;
}

- (NSSet *)removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    [self removeCookies:horizontalChains];
    [self removeCookies:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

- (void)removeCookies:(NSSet *)chains {
    for (RWTChain *chain in chains) {
        for (RWTCookie *cookie in chain.cookies) {
            _cookies[cookie.column][cookie.row] = nil;
        }
    }
}

- (void)performSwap:(RWTSwap *)swap
{
    NSInteger columnA = swap.cookieA.column;
    NSInteger rowA = swap.cookieA.row;
    NSInteger columnB = swap.cookieB.column;
    NSInteger rowB = swap.cookieB.row;
    
    _cookies[columnA][rowA] = swap.cookieB;
    swap.cookieB.column = columnA;
    swap.cookieB.row = rowA;
    
    _cookies[columnB][rowB] = swap.cookieA;
    swap.cookieA.column = columnB;
    swap.cookieA.row = rowB;
}

- (NSArray *)fillHoles
{
    NSMutableArray *columns = [NSMutableArray array];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        
        for (NSInteger row = 0; row < NumRows; row++) {
            if (_tiles[column][row] != nil && _cookies[column][row] == nil) {
                for (NSInteger lookup = row + 1; lookup < NumRows; lookup++) {
                    RWTCookie *cookie = _cookies[column][lookup];
                    if (cookie != nil) {
                        _cookies[column][lookup] = nil;
                        _cookies[column][row] = cookie;
                        cookie.row = row;
                        
                        if (array == nil) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:cookie];
                        
                        break;
                    }
                }
            }
        }
    }
    
    return columns;
}

- (NSArray *)topUpCookies
{
    NSMutableArray *columns = [NSMutableArray array];
    
    NSUInteger cookieType = 0;
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        
        for (NSInteger row = NumRows - 1; row >= 0 && _cookies[column][row] == nil; row--) {
            if (_tiles[column][row] != nil) {
                NSUInteger newCookieType;
                do {
                    newCookieType = arc4random_uniform(NumCookieTypes) + 1;
                } while (newCookieType == cookieType);
                
                cookieType = newCookieType;
                RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                if (array == nil) {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                
                [array addObject:cookie];
            }
        }
    }
    
    return columns;
}

- (void)calculateScores:(NSSet *)chains {
    for (RWTChain *chain in chains) {
        chain.score = 60 * ([chain.cookies count] - 2) * self.comboMultiplier;
        self.comboMultiplier++;
    }
}

- (void)resetComboMultiplier {
    self.comboMultiplier = 1;
}
@end

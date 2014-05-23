//
//  RWTLevel.m
//  CookieCrunch
//
//  Created by Yi Zeng on 5/22/14.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import "RWTLevel.h"

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
    }
    
    return self;
}

- (NSSet *)shuffle
{
    return [self createInitialCookies];
}

- (NSSet *)createInitialCookies
{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if (_tiles[column][row] != nil) {
                NSUInteger cookieType = arc4random_uniform(NumCookieTypes) + 1;
                
                RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                [set addObject:cookie];
            }
            
        }
    }
    
    return set;
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
@end

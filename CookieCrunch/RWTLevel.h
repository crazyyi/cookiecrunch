//
//  RWTLevel.h
//  CookieCrunch
//
//  Created by Yi Zeng on 5/22/14.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWTCookie.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface RWTLevel : NSObject

- (NSSet *)shuffle;

- (RWTCookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row;

@end

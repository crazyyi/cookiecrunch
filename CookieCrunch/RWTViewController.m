//
//  RWTViewController.m
//  CookieCrunch
//
//  Created by Yi Zeng on 5/22/14.
//  Copyright (c) 2014 afun. All rights reserved.
//

#import "RWTViewController.h"
#import "RWTMyScene.h"
#import "RWTLevel.h"

@interface RWTViewController()
@property (strong, nonatomic) RWTLevel *level;
@property (strong, nonatomic) RWTMyScene *scene;
@end

@implementation RWTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
    
    // Create and configure the scene.
    self.scene = [RWTMyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    self.level = [[RWTLevel alloc] init];
    self.scene.level = self.level;
    
    [skView presentScene:self.scene];
    
    [self beginGame];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)beginGame
{
    [self shuffle];
}

- (void)shuffle
{
    NSSet *newCookies = [self.level shuffle];
    [self.scene addSpriteForCookies:newCookies];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end

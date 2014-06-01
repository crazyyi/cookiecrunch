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
@import AVFoundation;

@interface RWTViewController()
@property (strong, nonatomic) RWTLevel *level;
@property (strong, nonatomic) RWTMyScene *scene;
@property (assign, nonatomic) NSUInteger movesLeft;
@property (assign, nonatomic) NSUInteger score;
@property (strong, nonatomic) AVAudioPlayer *backgroundMusic;

@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
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
    self.level = [[RWTLevel alloc] initWithFile:@"Level_1"];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    id block = ^(RWTSwap *swap) {
        self.view.userInteractionEnabled = NO;
        
        if ([self.level isPossibleSwap:swap]) {
            [self.level performSwap:swap];
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
                self.view.userInteractionEnabled = YES;
            }];
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
            
        }
        
    };
    
    self.scene.swipeHandler = block;
    
    self.gameOverPanel.hidden = YES;
    [skView presentScene:self.scene];
    
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Mining by Moonlight" withExtension:@"mp3"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    [self.backgroundMusic play];
    
    [self beginGame];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)beginGame
{
    [self.level resetComboMultiplier];
    [self.scene animateBeginGame];
    [self shuffle];
}

- (void)shuffle
{
    [self.scene removeAllCookieSprites];
    NSSet *newCookies = [self.level shuffle];
    [self.scene addSpriteForCookies:newCookies];
}

- (void)handleMatches {
    NSSet *chains = [self.level removeMatches];
    if ([chains count] == 0) {
        [self.level resetComboMultiplier];
        [self beginNextTurn];
        return;
    }
    
    [self.scene animateMatchedCookies:chains completion:^{
        
        for (RWTChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        NSArray *columns = [self.level fillHoles];
        
        [self.scene animateFallingCookies:columns completion:^{
            NSArray *columns = [self.level topUpCookies];
            [self.scene animateNewCookies:columns completion:^{
                [self handleMatches];
            }];
        }];
        
    }];
}

- (void)beginNextTurn {
    [self.level detectPossibleSwaps];
    self.view.userInteractionEnabled = YES;
    [self decrementMoves];
}

- (void)updateLabels
{
    self.targetLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
    
}

- (void)decrementMoves {
    self.movesLeft--;
    [self updateLabels];
    
    if (self.score >= self.level.targetScore) {
        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
        [self showGameOver];
    } else if (self.movesLeft == 0) {
        self.gameOverPanel.image = [UIImage imageNamed:@"GameOver"];
        [self showGameOver];
    }
}

- (void)showGameOver {
    self.gameOverPanel.hidden = NO;
    self.scene.userInteractionEnabled = NO;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    
    self.shuffleButton.hidden = YES;
}

- (void)hideGameOver
{
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scene.userInteractionEnabled = YES;
    self.shuffleButton.hidden = NO;
    
    self.score = 0;
    self.movesLeft = self.level.maximumMoves;
    [self updateLabels];
    [self beginGame];
}

- (IBAction)shuffleButtonPressed:(id)sender {
    [self shuffle];
    [self decrementMoves];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end

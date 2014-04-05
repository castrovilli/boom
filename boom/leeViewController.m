//
//  leeViewController.m
//  boom
//
//  Created by AJ Lee on 8/19/13.
//  Copyright (c) 2013 AJ Lee. All rights reserved.
//

#import "leeViewController.h"
#include <stdlib.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>

@interface leeViewController ()

@end

NSUInteger bCountCells = 99;
NSUInteger bCountColumns = 9;
NSUInteger *bBooms;
NSUInteger bCountBooms = 15;
NSUInteger *bBrowsed;
NSUInteger bCountBoomsTemp = 15;
NSString *bBoom = @"☠";
NSString *bWin = @"♕";
NSString *bNone = @"◎";
NSString *bFlag = @"⚐";
// ♳ ♴ ♵ ♶ ♷ ♸ ♹ ♺ ☢

bool isGameOver = false;
bool isOption = false;
bool isFirst = true;
bool isShowMessage = false;
NSTimer *timer;
UIColor* defaultColor;


@implementation leeViewController

- (void)viewDidLoad
{

    [super viewDidLoad];

    // Get defaut color
    defaultColor = [_btnChangeBooms titleColorForState: UIControlStateNormal];
	// Do any additional setup after loading the view, typically from a nib.
    [self initBooms];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

-(void)initBooms
{
    int x, y;
    UIView *vView = (UIView *)[self.view viewWithTag:102];
    UILabel *lblCountBooms = (UILabel *)[self.view viewWithTag:103];
    [lblCountBooms setText:[NSString stringWithFormat:@"%d", bCountBooms]];
    for (int i=0; i<bCountCells; i++) {
        x = ((i % bCountColumns) + 1) * 32 - 16;
        y = ((i / bCountColumns) + 1) * 32 - 30;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self action:@selector(pressTap:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:bNone forState:UIControlStateNormal];
        //[button setTitle:[NSString stringWithFormat:@"%d", i] forState:UIControlStateNormal];
        [button setShowsTouchWhenHighlighted:true];
        [button setTag:i];
        CGRect rect =  CGRectMake(x, y, 32, 32);
        [button setFrame:rect];
        [button.titleLabel setFont:[UIFont systemFontOfSize:21]];
        [button.layer setCornerRadius:0];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [button addGestureRecognizer:longPress];
        [vView addSubview:button];
        bBooms = (NSUInteger*)malloc(bCountBooms * sizeof(NSUInteger));
        bBrowsed = (NSUInteger*)malloc(bCountCells * sizeof(NSUInteger));
        [self generatorBooms];
    }
}

-(void)pressTap:(UIButton *)button
{
    if (!isGameOver && bBrowsed[[button tag]] == 0) {
        bBrowsed[[button tag]] = 1; // Is browsed
        // ♴ ♵ ♶ ♷ ♸ ♹ ♺ ☢
        if (isFirst) {
            [self startTimer];
            isFirst = false;
        }
        if([[[button titleLabel] text] isEqualToString:bFlag]){
            UILabel *label = (UILabel *)[self.view viewWithTag:103];
            NSUInteger flag = [[label text] integerValue];
            [label setText:[NSString stringWithFormat:@"%d", (flag+1)]];
        }
        switch ([self getNumbersBooms:button.tag]) {
            case 0:
                [self setTitleAndColor:button :@"" :[UIColor blueColor]];
                [self defusingBooms:button.tag];
                break;
            case 1:
                [self setTitleAndColor:button :@"♳" :[UIColor blueColor]];
                break;
            case 2:
                [self setTitleAndColor:button :@"♴" :[UIColor greenColor]];
                break;
            case 3:
                [self setTitleAndColor:button :@"♵" :[UIColor redColor]];
                break;
            case 4:
                [self setTitleAndColor:button :@"♶" :[UIColor purpleColor]];
                break;
            case 5:
                [self setTitleAndColor:button :@"♷" :[UIColor brownColor]];
                break;
            case 6:
                [self setTitleAndColor:button :@"♸" :[UIColor cyanColor]];
                break;
            case 7:
                [self setTitleAndColor:button :@"♹" :[UIColor cyanColor]];
                break;
            case 8:
                [self setTitleAndColor:button :@"☢" :[UIColor cyanColor]];
                break;
            case 9:
                isGameOver = true;
                [self stopTimer];
                [self playAudio:@"boomed" :@"wav"];
                [self setBooms:bBoom :[UIColor redColor]];
                [self showMessage :@"GAME OVER":bBoom];
                break;
        }
        if(!isGameOver){
            [self playAudio:@"boom" :@"wav"];
        }
    }
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    UILabel *label = (UILabel *)[self.view viewWithTag:103];
    NSUInteger flag = [[label text] integerValue];
    UIButton *button = (UIButton *)gesture.view;
    if (!isGameOver && flag > 0 && [button.titleLabel.text isEqualToString:bNone]) {
        [button setTitle:bFlag forState:UIControlStateNormal];
        // if (gesture.state == UIGestureRecognizerStateEnded) {
        [label setText:[NSString stringWithFormat:@"%d", (flag-1)]];
        [self playAudio:@"flag" :@"wav"];
        // }
    }
    if(flag == 0 && [self checkWin]){
        isGameOver = true;
        [self stopTimer];
        [self setBooms:bWin :[UIColor redColor]];
        [self showMessage:@"YOU ARE WINNER!":bWin];
        [self playAudio:@"win" :@"wav"];
    }
}

-(bool)checkWin{
    for (int i=0; i<bCountBooms; i++) {
        if (bBrowsed[bBooms[i]]==1) {
            return false;
        }
    }
    return true;
}

- (IBAction)btnNewGameTouchUpInside:(id)sender {
    [self newGame:bCountBooms];
}

-(void)newGame:(NSUInteger)booms
{
    [self stopTimer];
    /*
     free(bBooms);
     free(bBrowsed);
     bBooms = (NSUInteger*)malloc(bCountBooms * sizeof(NSUInteger));
     bBrowsed = (NSUInteger*)malloc(bCountCells * sizeof(NSUInteger));
     */
    bCountBooms = booms;
    [self generatorBooms];
    isGameOver = false;
    isFirst = true;
    UIView *vView = (UIView *)[self.view viewWithTag:102];
    for (int i=0; i<bCountCells; i++) {
        UIButton *button = (UIButton *)[vView viewWithTag:i];
        [button setTitle:bNone forState:UIControlStateNormal];
//        [button setTitleColor:[UIColor colorWithRed:36.0f/255.0f green:71.0f/255.0f blue:113.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [button setTitleColor:defaultColor forState:UIControlStateNormal];
    }
    UILabel *label = (UILabel *)[self.view viewWithTag:103];
    [label setText:[NSString stringWithFormat:@"%d", booms]];
    label = (UILabel *)[self.view viewWithTag:101];
    [label setText:@"0"];
}

- (IBAction)btnOptionTouchUpInside:(id)sender {
    isOption = true;
    switch (bCountBooms) {
        case 50:
            bCountBoomsTemp = 5;
            break;
        case 25:
            bCountBoomsTemp = 50;
            break;
        case 15:
            bCountBoomsTemp = 25;
            break;
        case 10:
            bCountBoomsTemp = 15;
            break;
        case 5:
            bCountBoomsTemp = 10;
            break;
    }
    if (isFirst) {
        [self newGame:bCountBoomsTemp];
    }
    else{
        [self showMessage:[NSString stringWithFormat:@"New game with %d booms?", bCountBoomsTemp]:bBoom];
    }
}

-(void) timeCounter:(NSTimer*)tmr{
    UILabel *label = (UILabel *)[self.view viewWithTag:101];
    [label setText:[NSString stringWithFormat:@"%d", [[label text] integerValue]+1]];
}

-(void)stopTimer{
    [timer invalidate];
    timer = nil;
}

-(void)startTimer
{
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeCounter:) userInfo:nil repeats:YES];
}

-(void)showMessage:(NSString *)message:(NSString *)icon
{
    if (!isShowMessage) {
        isShowMessage = true;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ BOOM %@", icon, icon]
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"BACK"
                                                  otherButtonTitles:@"NEW GAME",nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        isOption = false;
        isShowMessage = false;
    }
    if (buttonIndex == 1) {
        if(isOption){
            bCountBooms = bCountBoomsTemp;
            isOption = false;
        }
        isShowMessage = false;
        [self newGame:bCountBooms];
    }
}

-(void)setBooms:(NSString *)title:(UIColor *)color
{
    UIView *vView = (UIView *)[self.view viewWithTag:102];
    for (int i=0; i<bCountBooms; i++) {
        UIButton *button = (UIButton *)[vView viewWithTag:bBooms[i]];
        [self setTitleAndColor:button :title :color];
    }
}

-(void)setTitleAndColor:(UIButton *)button:(NSString *)title:(UIColor *)color
{
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];
}

-(void)playAudio:(NSString *)name:(NSString *)extension{
    SystemSoundID soundID;
    
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    NSURL *soundUrl = [NSURL fileURLWithPath:soundPath];
    
    AudioServicesCreateSystemSoundID ((__bridge CFURLRef)soundUrl, &soundID);
    AudioServicesPlaySystemSound(soundID);
}

-(void)defuseBooms:(NSUInteger)tag
{
    UIView *vView = (UIView *)[self.view viewWithTag:102];
    UIButton *button = (UIButton *)[vView viewWithTag:tag];
    if (bBrowsed[tag] == 0 && [[button titleLabel] text] != bFlag) {
        bBrowsed[tag] = 1;
        NSUInteger numbersBooms = [self getNumbersBooms:tag];
        switch (numbersBooms) {
            case 0:
                [self setTitleAndColor:button :@"" :[UIColor blueColor]];
                [self defusingBooms:tag];
                break;
            case 1:
                [self setTitleAndColor:button :@"♳" :[UIColor blueColor]];
                break;
            case 2:
                [self setTitleAndColor:button :@"♴" :[UIColor greenColor]];
                break;
            case 3:
                [self setTitleAndColor:button :@"♵" :[UIColor redColor]];
                break;
            case 4:
                [self setTitleAndColor:button :@"♶" :[UIColor purpleColor]];
                break;
            case 5:
                [self setTitleAndColor:button :@"♷" :[UIColor brownColor]];
                break;
            case 6:
                [self setTitleAndColor:button :@"♸" :[UIColor cyanColor]];
                break;
            case 7:
                [self setTitleAndColor:button :@"♹" :[UIColor cyanColor]];
                break;
            case 8:
                [self setTitleAndColor:button :@"☢" :[UIColor cyanColor]];
                break;
        }
    }
}

-(void)defusingBooms:(NSUInteger)input
{
    if (input == 0) {
        [self defuseBooms:1];
        [self defuseBooms:bCountColumns];
        [self defuseBooms:bCountColumns+1];
        return;
    }
    // 8
    if (input == (bCountColumns-1))    {
        [self defuseBooms:(input-1)];
        [self defuseBooms:(input+bCountColumns)];
        [self defuseBooms:(input+bCountColumns-1)];
        return;
    }
    // 90
    if (input == (bCountCells-bCountColumns)) {
        [self defuseBooms:(input-bCountColumns)];
        [self defuseBooms:(input-bCountColumns+1)];
        [self defuseBooms:(input+1)];
        return;
    }
    // 98
    if (input == (bCountCells-1)) {
        [self defuseBooms:(input-bCountColumns)];
        [self defuseBooms:(input-bCountColumns-1)];
        [self defuseBooms:(input-1)];
        return;
    }
    // below
    if (input < bCountColumns) {
        [self defuseBooms:(input-1)];
        [self defuseBooms:(input+1)];
        [self defuseBooms:(input+bCountColumns-1)];
        [self defuseBooms:(input+bCountColumns)];
        [self defuseBooms:(input+bCountColumns+1)];
        return;
    }
    // left
    if ((input % bCountColumns)==0) {
        [self defuseBooms:(input-bCountColumns)];
        [self defuseBooms:(input-bCountColumns)+1];
        [self defuseBooms:(input+1)];
        [self defuseBooms:(input+bCountColumns)];
        [self defuseBooms:(input+bCountColumns+1)];
        return;
    }
    // right
    if (((input+1) % bCountColumns)==0) {
        [self defuseBooms:(input-bCountColumns)];
        [self defuseBooms:(input-bCountColumns-1)];
        [self defuseBooms:(input-1)];
        [self defuseBooms:(input+bCountColumns)];
        [self defuseBooms:(input+bCountColumns-1)];
        return;
    }
    // ablow
    if (input >= (bCountCells - bCountColumns)) {
        [self defuseBooms:(input-1)];
        [self defuseBooms:(input+1)];
        [self defuseBooms:(input-bCountColumns)];
        [self defuseBooms:(input-bCountColumns+1)];
        [self defuseBooms:(input-bCountColumns-1)];
        return;
    }
    // center
    [self defuseBooms:(input-bCountColumns-1)];
    [self defuseBooms:(input-bCountColumns)];
    [self defuseBooms:(input-bCountColumns+1)];
    [self defuseBooms:(input+1)];
    [self defuseBooms:(input-1)];
    [self defuseBooms:(input+bCountColumns-1)];
    [self defuseBooms:(input+bCountColumns)];
    [self defuseBooms:(input+bCountColumns+1)];
    return;
}

-(NSUInteger)getNumbersBooms:(NSUInteger)input
{
    // Is boom
    if ([self checkExsits:input]) {
        return 9;
    }
    NSUInteger numbers = 0;
    //0
    if (input == 0) {
        numbers = [self checkExsits:1] ? numbers+1 : numbers;
        numbers = [self checkExsits:bCountColumns] ? numbers+1 : numbers;
        numbers = [self checkExsits:(bCountColumns+1)] ? numbers+1 : numbers;
        return numbers;
    }
    // 8
    if (input == (bCountColumns-1))
    {
        numbers = [self checkExsits:(input-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns-1)] ? numbers+1 : numbers;
        return numbers;
    }
    // 90
    if (input == (bCountCells-bCountColumns)) {
        numbers = [self checkExsits:(input-bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns+1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+1)] ? numbers+1 : numbers;
        return numbers;
    }
    // 98
    if (input == (bCountCells-1)) {
        numbers = [self checkExsits:(input-bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-1)] ? numbers+1 : numbers;
        return numbers;
    }
    // below
    if (input < bCountColumns) {
        numbers = [self checkExsits:(input-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns+1)] ? numbers+1 : numbers;
        return numbers;
    }
    // left
    if ((input % bCountColumns)==0) {
        numbers = [self checkExsits:(input-bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns)+1] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns+1)] ? numbers+1 : numbers;
        return numbers;
    }
    // right
    if (((input+1) % bCountColumns)==0) {
        numbers = [self checkExsits:(input-bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+bCountColumns-1)] ? numbers+1 : numbers;
        return numbers;
    }
    // ablow
    if (input >= (bCountCells - bCountColumns)) {
        numbers = [self checkExsits:(input-1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input+1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns+1)] ? numbers+1 : numbers;
        numbers = [self checkExsits:(input-bCountColumns-1)] ? numbers+1 : numbers;
        return numbers;
    }
    // center
    numbers = [self checkExsits:(input-bCountColumns-1)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input-bCountColumns)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input-bCountColumns+1)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input-1)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input+1)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input+bCountColumns-1)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input+bCountColumns)] ? numbers+1 : numbers;
    numbers = [self checkExsits:(input+bCountColumns+1)] ? numbers+1 : numbers;
    return numbers;
}

-(void)generatorBooms
{
    NSUInteger count = 0;
    NSUInteger ard;
    bBooms = (NSUInteger*)malloc(bCountBooms * sizeof(NSUInteger));
    while (count < bCountBooms) {
        ard = arc4random() % bCountCells;
        if (![self checkExsits:ard]) {
            bBooms[count] = ard;
            count++;
        }
    }
    for (int i=0; i<bCountCells; i++) {
        bBrowsed[i] = 0;
    }
}

-(bool)checkExsits:(NSUInteger)input
{
    for (int i=0; i<bCountBooms; i++) {
        if (bBooms[i] == input) {
            return true;
        }
    }
    return false;
}

@end

//
//  ViewController.h
//  StickAroundPrefs
//
//  Created by Alex Gallon on 24/07/2019.
//  Copyright © 2019 Squ1dd13. All rights reserved.
//

#import <UIKit/UIKit.h>
@import QuartzCore;

@interface ViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) UITextField *hexTextField;
@property (strong, nonatomic) UILabel *colorNameLabel;
@property (nonatomic, readwrite, strong) NSDictionary *colorNames;
@property (strong, nonatomic) UISlider *redSlider;
@property (strong, nonatomic) UISlider *greenSlider;
@property (strong, nonatomic) UISlider *blueSlider;
@property (strong, nonatomic) UILabel *rgbLabel;
@property (strong, nonatomic) UIButton *doneButton;
@property (nonatomic, assign, readwrite) UIColor *chosenColor;
@end

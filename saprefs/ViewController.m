//
//  ViewController.m
//  StickAroundPrefs
//
//  Created by Alex Gallon on 24/07/2019.
//  Copyright © 2019 Squ1dd13. All rights reserved.
//

#import "ViewController.h"
#include <sys/stat.h>

unsigned char hexDigitsToChar(NSString *hexDigits) {
    static NSString *digits = @"0123456789ABCDEF";

    const char sixteens = [digits rangeOfString:[NSString stringWithFormat:@"%c", [hexDigits characterAtIndex:0]]].location;

    const char units = [digits rangeOfString:[NSString stringWithFormat:@"%c", [hexDigits characterAtIndex:1]]].location;

    u_char result = sixteens * 16 + units;

    return result;
}

UIColor *colorFromString(NSString *hexStr) {
    hexStr = [hexStr stringByReplacingOccurrencesOfString:@"#" withString:@""];

    unsigned char allValues[3];

    char *digitPairs[3];
    for(int i = 0, iters = 0; i < 6; i += 2, iters++) {
        //NSLog(@"i = %d, iters = %d", i, iters);
        char thisPair[2] = { [hexStr characterAtIndex:i], [hexStr characterAtIndex:i + 1] };
        digitPairs[iters] = thisPair;
        allValues[iters] = hexDigitsToChar([NSString stringWithFormat:@"%s", thisPair]);
    }

    const CGFloat red = allValues[0];
    const CGFloat green = allValues[1];
    const CGFloat blue = allValues[2];

    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0f];
}

NSString *stringFromColor(UIColor *color) {
    const CGFloat *components = CGColorGetComponents(color.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

NSString *stringFromColor2(UIColor *color) {
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(red * 255),
            lroundf(green * 255),
            lroundf(blue * 255)];
}

UIColor *complementaryColor(UIColor *col) {
    CGFloat hue, saturation, brightness, alpha;
    [col getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    //Get the opposite hue.
    CGFloat oppositeHue = 1.0f - hue;
    return [UIColor colorWithHue:oppositeHue saturation:saturation brightness:brightness alpha:alpha];
}

UIColor *foregroundColorForBackground(UIColor *background) {
    CGFloat red, green, blue, alpha;
    [background getRed:&red green:&green blue:&blue alpha:&alpha];

    return (((red * 255 * 0.299) + (green * 255 * 0.587) + (blue * 255 * 0.114)) > 186) ? [UIColor colorWithRed:15 / 255 green:15 / 255 blue:15 / 255 alpha:1.0f] : [UIColor whiteColor];
}

@interface NSKeyedUnarchiver (TheosWontWorkHelp)
+(id)unarchivedObjectOfClass:(id)sth fromData:(id)ssth error:(id)sssth;
@end

NSDictionary *loadColorNames(NSString *file) {
    //The names and colours in the .plist are swapped around, because the colours (which should be the keys) are represented as NSData objects, whereas the names are NSStrings. Since a plist can't have NSData keys, they are swapped over.

    NSDictionary *loaded = [NSDictionary dictionaryWithContentsOfFile:file];

    NSMutableDictionary *swappedAndConverted = [NSMutableDictionary new];
    [loaded enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        swappedAndConverted[[NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:value error:nil]] = key;
    }];

    NSLog(@"%@", swappedAndConverted);

    return [swappedAndConverted copy];
}

UIColor *closestColor(UIColor *toColor, NSArray *fromColors) {
    UIColor *closestFound = nil;
    float closestDifference = CGFLOAT_MAX;

    //Get toColor's RGBA components.
    CGFloat r, g, b, a;
    [toColor getRed:&r green:&g blue:&b alpha:&a];

    for(UIColor *color in fromColors) {
        //Get the RGBA components.
        CGFloat red, green, blue, alpha;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];

        //Get the average difference across R, G & B.
        const float thisDifference = (fabs(r - red) +
                                      fabs(g - green) +
                                      fabs(b - blue)) / 3.0f;

        if(thisDifference < closestDifference) {
            closestFound = color;
            closestDifference = thisDifference;
        }
    }

    return closestFound;
}

NSString *getColorName(UIColor *color, NSDictionary *colorsAndNames) {
    //NSLog(@"%@", colorsAndNames);


    //Get the closest key from the dict.
    UIColor *closestKey = closestColor(color, [colorsAndNames allKeys]);

    return colorsAndNames[closestKey];
}

UIImage *getImageFromColor(UIColor *color, CGSize imageSize) {
    CGRect rect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@interface ViewController ()

@end

@implementation ViewController

-(id)initWithDefaultsKey:(NSString *)key domain:(NSString *)defaultsDomain defaultColor:(UIColor *)defaultColor {
    self = [super init];
    if(self) {
        self.defaultsKey = key;
        self.defaultsDomain = defaultsDomain;

        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:defaultsDomain];
        if(![defaults objectForKey:key]) {
            //There is no saved colour. If we have a default colour, set that, but if not, use [UIColor blackColor] instead.
            [defaults setObject:defaultColor ? stringFromColor(defaultColor) : @"#000000" forKey:key];

            //Do this here rather than doing it before and converting to hex - we already know the hex value for black.
            self.chosenColor = defaultColor ? defaultColor : [UIColor blackColor];
        } else {
            NSLog(@"%@", [defaults objectForKey:key]);
            self.chosenColor = colorFromString([defaults objectForKey:key]);
        }
    }

    return self;
}

-(void)loadView {
    [super loadView];

    self.redSlider = [[UISlider alloc] initWithFrame:self.view.frame];
    self.greenSlider = [[UISlider alloc] initWithFrame:self.view.frame];
    self.blueSlider = [[UISlider alloc] initWithFrame:self.view.frame];

    self.redSlider.value = 0.0;
    self.redSlider.minimumValue = 0.0;
    self.redSlider.maximumValue = 255.0;

    self.greenSlider.value = 0.0;
    self.greenSlider.minimumValue = 0.0;
    self.greenSlider.maximumValue = 255.0;

    self.blueSlider.value = 0.0;
    self.blueSlider.minimumValue = 0.0;
    self.blueSlider.maximumValue = 255.0;

    self.hexTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 319.0, 375.0, 30.0)];
    self.hexTextField.minimumFontSize = 13.0;
    self.hexTextField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBlack];
    self.hexTextField.textAlignment = NSTextAlignmentCenter;

    self.colorNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 268.0, 375.0, 42.0)];
    self.colorNameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBlack];
    self.colorNameLabel.textAlignment = NSTextAlignmentCenter;

    self.rgbLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 490.0, 375.0, 42.0)];
    self.rgbLabel.font = self.colorNameLabel.font;
    self.rgbLabel.textAlignment = NSTextAlignmentCenter;

    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.frame = CGRectMake(112.0, 573.0, 99.0, 34.0);
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    self.doneButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    self.doneButton.clipsToBounds = YES;
    [self.doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

    [self.view addSubview:self.redSlider];
    [self.view addSubview:self.greenSlider];
    [self.view addSubview:self.blueSlider];
    [self.view addSubview:self.hexTextField];
    [self.view addSubview:self.colorNameLabel];
    [self.view addSubview:self.rgbLabel];
    [self.view addSubview:self.doneButton];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"ColourMap" ofType:@"plist"];
    self.colorNames = loadColorNames(path);

    [self.hexTextField addTarget:self action:@selector(textFieldDidChange:)
          forControlEvents:UIControlEventEditingChanged];

    self.hexTextField.backgroundColor = [UIColor clearColor];
    self.hexTextField.borderStyle = UITextBorderStyleNone;
    CGRect frame = self.hexTextField.frame;
    frame.size.width = self.view.frame.size.width;

    const int sliderWidth = self.view.frame.size.width * 0.67;

    CGRect sliderFrame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, sliderWidth, 31);
    self.redSlider.frame = sliderFrame;
    self.greenSlider.frame = sliderFrame;
    self.blueSlider.frame = sliderFrame;

    self.colorNameLabel.frame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - 40, self.view.frame.size.width, 42);

    self.hexTextField.frame = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, self.view.frame.size.width, 30);

    //self.hexTextField.frame = frame;
    self.hexTextField.delegate = self;
    self.hexTextField.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - 80);
    self.colorNameLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 - self.colorNameLabel.frame.size.height - 80);

    self.redSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 50 - 80);

    self.greenSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 100 - 80);

    self.blueSlider.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 150 - 80);

    self.rgbLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 200 - 80);

    self.doneButton.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2 + 300 - 80);

    [self.redSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [self.greenSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [self.blueSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    [self.doneButton addTarget:self action:@selector(excuseSelf:) forControlEvents:UIControlEventTouchUpInside];

    self.doneButton.layer.cornerRadius = 8.0f;

    [self.doneButton setTitleColor:self.view.backgroundColor forState:UIControlStateNormal];

    //Show the first colour.
    [self updateWithColor:self.chosenColor];
}

-(void)sliderValueChanged:(UISlider *)slidey {
    CGFloat red = self.redSlider.value, green = self.greenSlider.value, blue = self.blueSlider.value;
    UIColor *newColor = [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0f];

    //Trigger other UI updates.
    [self updateWithColor:newColor];
}

-(void)textFieldDidChange:(UITextField *)tf {
    NSCharacterSet *illegalCharacters = [NSCharacterSet characterSetWithCharactersInString:@"#0123456789ABCDEF"].invertedSet;
    if(tf.text.length < 7 || [[tf.text uppercaseString] rangeOfCharacterFromSet:illegalCharacters].location != NSNotFound) return;

    [self updateWithColor:colorFromString([tf.text uppercaseString])];
}

-(void)updateWithColor:(UIColor *)color {
    self.chosenColor = self.view.backgroundColor = color;

    self.doneButton.titleLabel.textColor = color;

    [self.hexTextField setText:stringFromColor(self.chosenColor)];

    if(![self.view.backgroundColor isEqual:[UIColor colorWithRed:self.redSlider.value / 255.0 green:self.greenSlider.value / 255.0 blue:self.blueSlider.value / 255.0 alpha:1.0f]]) {
        //Update the sliders.
        CGFloat red, green, blue, alpha;
        [self.view.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];

        //For some reason this doesn't always animate.
        [UIView animateWithDuration:0.2 animations:^{
            [self.redSlider setValue:red * 255.0 animated:YES];
            [self.greenSlider setValue:green * 255.0 animated:YES];
            [self.blueSlider setValue:blue * 255.0 animated:YES];
        }];
    }

    UIColor *foregroundColor = foregroundColorForBackground(self.view.backgroundColor);
    [self.doneButton setBackgroundImage:getImageFromColor(foregroundColor, self.doneButton.frame.size) forState:UIControlStateNormal];

    CGFloat red, green, blue, alpha;
    [foregroundColor getRed:&red green:&green blue:&blue alpha:&alpha];

    UIColor *dimmedForegroundColor = [UIColor colorWithRed:red * 0.6 green:green * 0.6 blue:blue * 0.6 alpha:alpha];
    [self.doneButton setBackgroundImage:getImageFromColor(dimmedForegroundColor, self.doneButton.frame.size) forState:UIControlStateHighlighted];

    [self.doneButton setTitleColor:self.view.backgroundColor forState:UIControlStateNormal];

    self.redSlider.minimumTrackTintColor = foregroundColor;
    self.greenSlider.minimumTrackTintColor = foregroundColor;
    self.blueSlider.minimumTrackTintColor = foregroundColor;

    self.hexTextField.textColor = foregroundColor;
    self.colorNameLabel.textColor = foregroundColor;

    self.redSlider.maximumTrackTintColor = foregroundColor;
    self.greenSlider.maximumTrackTintColor = foregroundColor;
    self.blueSlider.maximumTrackTintColor = foregroundColor;

    self.rgbLabel.textColor = foregroundColor;

    self.redSlider.thumbTintColor = foregroundColor;
    self.greenSlider.thumbTintColor = foregroundColor;
    self.blueSlider.thumbTintColor = foregroundColor;

    self.colorNameLabel.text = getColorName(self.view.backgroundColor, _colorNames);

    self.rgbLabel.text = [NSString stringWithFormat:@"R: %.0f   G: %.0f   B: %.0f", self.redSlider.value, self.greenSlider.value, self.blueSlider.value];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    if(textField.tag != 940) return YES;

    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }

    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    if(newLength >= 8) {
        return NO;
    }

    NSRange protectedRange = NSMakeRange(0, 1);
    NSRange intersection = NSIntersectionRange(protectedRange, range);
    if(intersection.length > 0) {
        return NO;
    }

    NSRange lowercaseCharRange = [string rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]];

    if (lowercaseCharRange.location != NSNotFound) {
        textField.text = [textField.text stringByReplacingCharactersInRange:range
                                                                 withString:[string uppercaseString]];
        return NO;
    }

    NSRange illegalCharRange = [string rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"#0123456789ABCDEF"].invertedSet];
    if(illegalCharRange.location != NSNotFound) return NO;

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(void)excuseSelf:(UIButton *)btn {
    self.chosenColor = self.view.backgroundColor;

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:self.defaultsDomain];
    [defaults setObject:stringFromColor(self.chosenColor) forKey:self.defaultsKey];
    [defaults synchronize];

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

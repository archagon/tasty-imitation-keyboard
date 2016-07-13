//
//  CYRKeyboardButtonView.m
//
//  Created by Illya Busigin on 7/19/14.
//  Copyright (c) 2014 Cyrillian, Inc.
//  Portions Copyright (c) 2013 Nigel Timothy Barber (TurtleBezierPath)
//
//  Distributed under MIT license.
//  Get the latest version from here:
//
//  https://github.com/illyabusigin/CYRKeyboardButton
//
// The MIT License (MIT)
//
// Copyright (c) 2014 Cyrillian, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "CYRKeyboardButtonView.h"
#import "CYRKeyboardButton.h"
#import "TurtleBezierPath.h"

@interface CYRKeyboardButtonView ()<UIGestureRecognizerDelegate>
{
	NSCharacterSet *firstRowChar;
}
@property (nonatomic, weak) CYRKeyboardButton *button;
@property (nonatomic, assign) CYRKeyboardButtonViewType type;
@property (nonatomic, assign) CYRKeyboardButtonPosition expandedPosition;
@property (nonatomic, strong) NSMutableArray *inputOptionRects;
@property (nonatomic, assign) NSInteger selectedInputIndex;


@end

@implementation CYRKeyboardButtonView
@synthesize inPutOptionSelectView;
#pragma mark - UIView

- (instancetype)initWithKeyboardButton:(CYRKeyboardButton *)button type:(CYRKeyboardButtonViewType)type;
{
    CGRect frame = [UIScreen mainScreen].bounds;
	
	firstRowChar = [[NSCharacterSet characterSetWithCharactersInString:@"QWERTYUIOPqwertyuiop"] invertedSet];
	
	if (self.bounds.size.width>self.bounds.size.height) {
		frame = CGRectMake(0, 0, CGRectGetHeight(frame), CGRectGetWidth(frame));
	}
	
    self = [super initWithFrame:frame];
    
    if (self) {
        _button = button;
        _type = type;
        _selectedInputIndex = 0;
        
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        if (button.position != CYRKeyboardButtonPositionInner)
        {
            _expandedPosition = button.position;
        }
        else
        {
            // Determine the position
            CGFloat leftPadding = CGRectGetMinX(button.frame);
            CGFloat rightPadding = CGRectGetMaxX(button.superview.frame) - CGRectGetMaxX(button.frame);
            
            _expandedPosition = (leftPadding > rightPadding ? CYRKeyboardButtonPositionLeft : CYRKeyboardButtonPositionRight);
        }
    }
	
	
    return self;
}

- (void)didMoveToSuperview
{
    if (_type == CYRKeyboardButtonViewTypeExpanded) {
        [self determineExpandedKeyGeometries];
    }
}

#pragma mark - Public

- (void)updateSelectedInputIndexForPoint:(CGPoint)point
{
    __block NSInteger selectedInputIndex = NSNotFound;
    
    CGRect testRect = CGRectMake(point.x, point.y, 0, 0);
    
    CGPoint location = [self convertRect:testRect fromView:self.button.superview].origin;
    
    [self.inputOptionRects enumerateObjectsUsingBlock:^(NSValue *rectValue, NSUInteger idx, BOOL *stop) {
        CGRect keyRect = [rectValue CGRectValue];
        CGRect infiniteKeyRect = CGRectMake(CGRectGetMinX(keyRect), 0, CGRectGetWidth(keyRect), NSIntegerMax);
        infiniteKeyRect = CGRectInset(infiniteKeyRect, -3, 0);
        
        if (CGRectContainsPoint(infiniteKeyRect, location)) {
            selectedInputIndex = idx;
            *stop = YES;
        }
    }];
    
    
    if(selectedInputIndex == NSNotFound)
    {
        if (self.selectedInputIndex != 0)
        {
            self.selectedInputIndex = 0;
            //[self setNeedsDisplay];
            [self drawCustomSelectedViewFromIndex];
        }
        
    }
    else if (self.selectedInputIndex != selectedInputIndex) {
		
		if (ABS(self.selectedInputIndex - selectedInputIndex) == 1)
		{
			self.selectedInputIndex = selectedInputIndex;
			//[self setNeedsDisplay];
			[self drawCustomSelectedViewFromIndex];
			
		}
		
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    switch (_type) {
        case CYRKeyboardButtonViewTypeInput:
            [self drawInputView:rect];
            break;
            
        case CYRKeyboardButtonViewTypeExpanded:
            [self drawExpandedInputView:rect];
            break;
            
        default:
            break;
    }
	
	[self drawCustomSelectedViewFromIndex];
}

- (void)drawInputView:(CGRect)rect
{
    // Generate the overlay
    UIBezierPath *bezierPath = [self inputViewPath];
    NSString *inputString = self.button.input;
    
    // Position the overlay
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Overlay path & shadow
    {
        //// Shadow Declarations
        UIColor* shadow = [[UIColor blackColor] colorWithAlphaComponent: 0.5];
        CGSize shadowOffset = CGSizeMake(0, 0.5);
        CGFloat shadowBlurRadius = 2;
        
        //// Rounded Rectangle Drawing
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [self.button.keyColor setFill];
        [bezierPath fill];
        CGContextRestoreGState(context);
    }
    
    // Draw the key shadow sliver
    {
        //// Color Declarations
        UIColor *color = self.button.keyColor;
        
        //// Shadow Declarations
        UIColor *shadow = self.button.keyShadowColor;
        CGSize shadowOffset = CGSizeMake(0.1, 1.1);
        CGFloat shadowBlurRadius = 0;
        
        //// Rounded Rectangle Drawing
        UIBezierPath *roundedRectanglePath =
        [UIBezierPath bezierPathWithRoundedRect:CGRectMake(keyRect.origin.x, keyRect.origin.y, keyRect.size.width, keyRect.size.height - 1) cornerRadius:4];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [color setFill];
        [roundedRectanglePath fill];
        
        CGContextRestoreGState(context);
    }
    
    // Text drawing
    {
        UIColor *stringColor = self.button.keyTextColor;
        
        CGRect stringRect = bezierPath.bounds;
        
        NSMutableParagraphStyle *p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
        
        NSAttributedString *attributedString = [[NSAttributedString alloc]
                                                initWithString:inputString
                                                attributes:
                                                @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:44], NSForegroundColorAttributeName : stringColor, NSParagraphStyleAttributeName : p}];
        [attributedString drawInRect:stringRect];
    }
}

- (void)drawExpandedInputView:(CGRect)rect
{
    // Generate the overlay
    UIBezierPath *bezierPath = [self expandedInputViewPath];
    
    // Position the overlay
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Overlay path & shadow
    {
        CGFloat shadowAlpha = 0;
        CGSize shadowOffset;
        
        switch ([UIDevice currentDevice].userInterfaceIdiom) {
            case UIUserInterfaceIdiomPhone:
                shadowAlpha = 0.5;
                shadowOffset = CGSizeMake(0, 0.5);
                break;
                
            case UIUserInterfaceIdiomPad:
                shadowAlpha = 0.25;
                shadowOffset = CGSizeZero;
				
                break;
                
            default:
                break;
        }
        
        //// Shadow Declarations
        UIColor* shadow = [[UIColor blackColor] colorWithAlphaComponent: shadowAlpha];
        CGFloat shadowBlurRadius = 2;
        
        //// Rounded Rectangle Drawing
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [self.button.keyColor setFill];
        [bezierPath fill];
        CGContextRestoreGState(context);
    }
    
    // Draw the key shadow sliver
    if (self.button.style == CYRKeyboardButtonStylePhone) {
        UIColor *color = self.button.keyColor;
        
        //// Shadow Declarations
        UIColor *shadow = self.button.keyShadowColor;
        CGSize shadowOffset = CGSizeMake(0.1, 1.1);
        CGFloat shadowBlurRadius = 0;
        
        //// Rounded Rectangle Drawing
        UIBezierPath *roundedRectanglePath =
        [UIBezierPath bezierPathWithRoundedRect:CGRectMake(keyRect.origin.x, keyRect.origin.y, keyRect.size.width, keyRect.size.height - 1) cornerRadius:4];
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [color setFill];
        [roundedRectanglePath fill];
        
        CGContextRestoreGState(context);
    }
    
    [self drawExpandedInputViewOptions];
}

- (void)drawExpandedInputViewOptions
{
	
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShadowWithColor(context, CGSizeZero, 0, [[UIColor clearColor] CGColor]);
    CGContextSaveGState(context);
    
    NSArray *inputOptions = self.button.inputOptions;
    
    [inputOptions enumerateObjectsUsingBlock:^(NSString *optionString, NSUInteger idx, BOOL *stop) {
        CGRect optionRect = [self.inputOptionRects[idx] CGRectValue];
		
		UIFont *fontt ;
		
		if (optionString.length > 1)
		{
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				fontt = self.button.inputOptionsFont;
			}
			else
			{
				fontt = [UIFont systemFontOfSize:18];
				if (![self isLandScapeOrientation])
				{
					if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
					{
						optionRect.origin.x = optionRect.origin.x + 10;
					}
					else
					{
						optionRect.origin.x = optionRect.origin.x - 10;
					}
					
					
				}
				else
				{
					if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
					{
						//optionRect.origin.x = optionRect.origin.x - 12;
					}
					else
					{
						optionRect.origin.x = optionRect.origin.x + 12;
					}
					
				}
			}
			
			
		}
		else
		{
			fontt = self.button.inputOptionsFont;
		}
		
		
        BOOL selected = (idx == self.selectedInputIndex);
        
        if (selected) {
            // Draw selection background
//            UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:optionRect cornerRadius:4];
//            
//            [[UIColor grayColor] setFill];
//            [roundedRectanglePath fill];
        }
		
        // Draw the text
        //UIColor *stringColor = (selected ? [UIColor whiteColor] : self.button.keyTextColor);
		UIColor *stringColor = self.button.keyTextColor;
        CGSize stringSize = [optionString sizeWithAttributes:@{NSFontAttributeName : self.button.inputOptionsFont}];
        CGRect stringRect = CGRectMake(
                                       CGRectGetMidX(optionRect) - stringSize.width / 2, CGRectGetMidY(optionRect) - stringSize.height / 2, stringSize.width, stringSize.height);
        
        NSMutableParagraphStyle *p = [NSMutableParagraphStyle new];
        p.alignment = NSTextAlignmentCenter;
		
		
        NSAttributedString *attributedString = [[NSAttributedString alloc]
                                                initWithString:optionString
                                                attributes:
                                                @{NSFontAttributeName : fontt, NSForegroundColorAttributeName : stringColor, NSParagraphStyleAttributeName : p}];
        [attributedString drawInRect:stringRect];
    }];
    
    CGContextRestoreGState(context);
	 
	 
}


-(void)drawCustomSelectedViewFromIndex
{
	CGRect optionRect = [self.inputOptionRects[self.selectedInputIndex] CGRectValue];
	
	NSString *optionString = self.button.inputOptions[0];
	if (optionString.length > 1)
	{
		if (![self isLandScapeOrientation])
		{
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				optionRect.origin.x = optionRect.origin.x ;
			}
			else
			{
				optionRect.origin.x = optionRect.origin.x - 10;
			}
			
		}
		else
		{
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				//optionRect.origin.x = optionRect.origin.x - 12;
			}
			else
			{
				optionRect.origin.x = optionRect.origin.x + 12;
			}
			
		}
	}
	
	
	if (inPutOptionSelectView == nil)
	{
		inPutOptionSelectView = [[UIView alloc]initWithFrame:optionRect];
		inPutOptionSelectView.backgroundColor = [UIColor clearColor];
		
		inPutOptionSelectView.layer.cornerRadius = 4;
        inPutOptionSelectView.layer.borderColor = [[UIColor blueColor] colorWithAlphaComponent:0.5].CGColor;//[UIColor blueColor].CGColor;
		inPutOptionSelectView.layer.borderWidth = 1;
		
		[self addSubview:inPutOptionSelectView];
		
	}
	inPutOptionSelectView.frame = optionRect;
}

#pragma mark - Internal

- (UIBezierPath *)inputViewPath
{
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];
	
    UIEdgeInsets insets = UIEdgeInsetsMake(7, 13, 7, 13);
    CGFloat upperWidth = CGRectGetWidth(_button.frame) + insets.left + insets.right;
    CGFloat lowerWidth = CGRectGetWidth(_button.frame);
    CGFloat majorRadius = 10.f;
    CGFloat minorRadius = 4.f;
    
    TurtleBezierPath *path = [TurtleBezierPath new];
    [path home];
    path.lineWidth = 0;
    path.lineCapStyle = kCGLineCapRound;
    
    switch (self.button.position) {
        case CYRKeyboardButtonPositionInner:
        {
			if ([self.button.input rangeOfCharacterFromSet:firstRowChar].location == NSNotFound)
			{
				[path rightArc:majorRadius turn:90]; // #1
				[path forward:upperWidth - 2 * majorRadius]; // #2 top
				[path rightArc:majorRadius turn:90]; // #3
				
				[path forward:(CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom) - 4]; // #4 right big
				
				[path rightArc:majorRadius turn:48]; // #5
				[path forward:8.5f];
				[path leftArc:majorRadius turn:48]; // #6
				
				[path forward:CGRectGetHeight(keyRect) - 8.5f + 1 - 10];//lower small left
				
				[path rightArc:minorRadius turn:90];
				[path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
				[path rightArc:minorRadius turn:90];
				
				[path forward:(CGRectGetHeight(keyRect) - 2 * minorRadius) - 10];//lower small right
				
				[path leftArc:majorRadius turn:48];
				[path forward:8.5f];
				[path rightArc:majorRadius turn:48];
				
				
				CGFloat offsetX = 0, offsetY = 0;
				CGRect pathBoundingBox = path.bounds;
				
				offsetX = CGRectGetMidX(keyRect) - CGRectGetMidX(path.bounds);
				offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) + 10;
				
				[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
			}
			else
			{
				
				[path rightArc:majorRadius turn:90]; // #1
				[path forward:upperWidth - 2 * majorRadius]; // #2 top
				[path rightArc:majorRadius turn:90]; // #3
				[path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom]; // #4 right big
				[path rightArc:majorRadius turn:48]; // #5
				[path forward:8.5f];
				[path leftArc:majorRadius turn:48]; // #6
				[path forward:CGRectGetHeight(keyRect) - 8.5f + 1];
				[path rightArc:minorRadius turn:90];
				[path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
				[path rightArc:minorRadius turn:90];
				[path forward:CGRectGetHeight(keyRect) - 2 * minorRadius];
				[path leftArc:majorRadius turn:48];
				[path forward:8.5f];
				[path rightArc:majorRadius turn:48];
				
				CGFloat offsetX = 0, offsetY = 0;
				CGRect pathBoundingBox = path.bounds;
				
				offsetX = CGRectGetMidX(keyRect) - CGRectGetMidX(path.bounds);
				offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) + 10;
				
				[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];

			}
			
		}
            break;
			
        case CYRKeyboardButtonPositionLeft:
        {
			if ([self.button.input rangeOfCharacterFromSet:firstRowChar].location == NSNotFound)
			{
				[path rightArc:majorRadius turn:90]; // #1
				[path forward:upperWidth - 2 * majorRadius]; // #2 top
				[path rightArc:majorRadius turn:90]; // #3
				[path forward:(CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom)-5]; // #4 right big
				[path rightArc:majorRadius turn:45]; // #5
				[path forward:28]; // 6
				[path leftArc:majorRadius turn:45]; // #7
				[path forward:(CGRectGetHeight(keyRect) - 26 + (insets.left + insets.right) / 4) - 10]; // #8
				[path rightArc:minorRadius turn:90]; // 9
				[path forward:path.currentPoint.x - minorRadius]; // 10
				[path rightArc:minorRadius turn:90]; // 11
				
				
				CGFloat offsetX = 0, offsetY = 0;
				CGRect pathBoundingBox = path.bounds;
				
				offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(path.bounds);
				offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) - CGRectGetMinY(path.bounds);
				
				[path applyTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), -offsetX - CGRectGetWidth(path.bounds), offsetY)];
			}
			else
			{
				
				[path rightArc:majorRadius turn:90]; // #1
				[path forward:upperWidth - 2 * majorRadius]; // #2 top
				[path rightArc:majorRadius turn:90]; // #3
				[path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom]; // #4 right big
				[path rightArc:majorRadius turn:45]; // #5
				[path forward:28]; // 6
				[path leftArc:majorRadius turn:45]; // #7
				[path forward:CGRectGetHeight(keyRect) - 26 + (insets.left + insets.right) / 4]; // #8
				[path rightArc:minorRadius turn:90]; // 9
				[path forward:path.currentPoint.x - minorRadius]; // 10
				[path rightArc:minorRadius turn:90]; // 11
				
				
				CGFloat offsetX = 0, offsetY = 0;
				CGRect pathBoundingBox = path.bounds;
				
				offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(path.bounds);
				offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) - CGRectGetMinY(path.bounds);
				
				[path applyTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), -offsetX - CGRectGetWidth(path.bounds), offsetY)];
			}
			
        }
            break;
			
        case CYRKeyboardButtonPositionRight:
        {
			if ([self.button.input rangeOfCharacterFromSet:firstRowChar].location == NSNotFound)
			{
				[path rightArc:majorRadius turn:90]; // #1
				[path forward:upperWidth - 2 * majorRadius]; // #2 top
				[path rightArc:majorRadius turn:90]; // #3
				[path forward:(CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom) - 5]; // #4 right big
				[path rightArc:majorRadius turn:45]; // #5
				[path forward:28]; // 6
				[path leftArc:majorRadius turn:45]; // #7
				[path forward:(CGRectGetHeight(keyRect) - 26 + (insets.left + insets.right) / 4) - 10]; // #8
				[path rightArc:minorRadius turn:90]; // 9
				[path forward:path.currentPoint.x - minorRadius]; // 10
				[path rightArc:minorRadius turn:90]; // 11
				
				CGFloat offsetX = 0, offsetY = 0;
				CGRect pathBoundingBox = path.bounds;
				
				offsetX = CGRectGetMinX(keyRect);
				offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) - CGRectGetMinY(path.bounds);
				
				[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
			}
			else
			{
				[path rightArc:majorRadius turn:90]; // #1
				[path forward:upperWidth - 2 * majorRadius]; // #2 top
				[path rightArc:majorRadius turn:90]; // #3
				[path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom]; // #4 right big
				[path rightArc:majorRadius turn:45]; // #5
				[path forward:28]; // 6
				[path leftArc:majorRadius turn:45]; // #7
				[path forward:CGRectGetHeight(keyRect) - 26 + (insets.left + insets.right) / 4]; // #8
				[path rightArc:minorRadius turn:90]; // 9
				[path forward:path.currentPoint.x - minorRadius]; // 10
				[path rightArc:minorRadius turn:90]; // 11
				
				CGFloat offsetX = 0, offsetY = 0;
				CGRect pathBoundingBox = path.bounds;
				
				offsetX = CGRectGetMinX(keyRect);
				offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(pathBoundingBox) - CGRectGetMinY(path.bounds);
				
				[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
			}
			
			
        }
            break;
			
        default:
            break;
    }

    return path;
}

- (UIBezierPath *)expandedInputViewPath
{
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];
	
	NSString *optionChar = self.button.inputOptions[0];
	
	float widthOneOption = 0.0;//= CGRectGetWidth(keyRect) * optionChar.length;
	
	for (NSString *strOption in self.button.inputOptions)
	{
		if (strOption.length > 1)
		{
			CGSize stringSize = [strOption sizeWithAttributes:@{NSFontAttributeName : self.button.inputOptionsFont}];
			widthOneOption = widthOneOption + stringSize.width;
			
		}
	}
	
    UIEdgeInsets insets = UIEdgeInsetsMake(7, 13, 7, 13);
    CGFloat margin = 7.f;
	
	CGFloat upperWidth;

	if (optionChar.length > 1)
	{
		upperWidth = insets.left + insets.right + widthOneOption + margin * (self.button.inputOptions.count - 1) - margin/2;
	}
	else
	{
		upperWidth = insets.left + insets.right + self.button.inputOptions.count * CGRectGetWidth(keyRect) + margin * (self.button.inputOptions.count - 1) - margin/2;
	}
	
	
	
    CGFloat lowerWidth = CGRectGetWidth(_button.frame);
    CGFloat majorRadius = 10.f;
    CGFloat minorRadius = 4.f;
    
    TurtleBezierPath *path = [TurtleBezierPath new];
    [path home];
    path.lineWidth = 0;
    path.lineCapStyle = kCGLineCapRound;
    
    CGFloat offsetX = 0, offsetY = 0;
    
    switch (_expandedPosition) {
        case CYRKeyboardButtonPositionRight:
        {
            switch (self.button.style) {
                case CYRKeyboardButtonStylePhone:
                {
					
					if ([self.button.input rangeOfCharacterFromSet:firstRowChar].location == NSNotFound)
					{
						[path rightArc:majorRadius turn:90]; // #1
						[path forward:(upperWidth - 2 * majorRadius) - 28]; // #2 top
						[path rightArc:majorRadius turn:90]; // #3
						
						[path forward:(CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom - 3) - 5]; // #4 right big
						
						[path rightArc:majorRadius turn:90]; // #5
						[path forward:path.currentPoint.x - (CGRectGetWidth(keyRect) + 2 * majorRadius + 3)];
						[path leftArc:majorRadius turn:90]; // #6
						
						[path forward:(CGRectGetHeight(keyRect) - minorRadius) - 20];
						
						[path rightArc:minorRadius turn:90];
						[path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
						[path rightArc:minorRadius turn:90];
						
						[path forward:(CGRectGetHeight(keyRect) - 2 * minorRadius) - 20];
						
						[path leftArc:majorRadius turn:48];
						[path forward:8.5f];
						[path rightArc:majorRadius turn:48];
						
						offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(keyRect) - insets.left;
						offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(path.bounds) + 10;
						
						[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
					}
					else
					{
						
						
						[path rightArc:majorRadius turn:90]; // #1
						[path forward:upperWidth - 2 * majorRadius]; // #2 top
						[path rightArc:majorRadius turn:90]; // #3
						[path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom - 3]; // #4 right big
						[path rightArc:majorRadius turn:90]; // #5
						[path forward:path.currentPoint.x - (CGRectGetWidth(keyRect) + 2 * majorRadius + 3)];
						[path leftArc:majorRadius turn:90]; // #6
						[path forward:CGRectGetHeight(keyRect) - minorRadius];
						[path rightArc:minorRadius turn:90];
						[path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
						[path rightArc:minorRadius turn:90];
						[path forward:CGRectGetHeight(keyRect) - 2 * minorRadius];
						[path leftArc:majorRadius turn:48];
						[path forward:8.5f];
						[path rightArc:majorRadius turn:48];
						
						offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(keyRect) - insets.left;
						offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(path.bounds) + 10;
						
						[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
					}
					
					
					
					
                }
                    break;
					
                case CYRKeyboardButtonStyleTablet:
                {
                    CGRect firstRect = [self.inputOptionRects[0] CGRectValue];
					
                    path = (id)[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, CGRectGetWidth(firstRect) * self.button.inputOptions.count + 12, CGRectGetHeight(firstRect) + 12)
                                                          cornerRadius:6];
                    
                    offsetX = CGRectGetMinX(keyRect);
                    offsetY = CGRectGetMinY(firstRect) - 6;
                    
                    [path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
                    
                }
                    break;
                    
                default:
                    break;
            }
            
            
        }
            break;
            
        case CYRKeyboardButtonPositionLeft:
        {
            switch (self.button.style) {
                case CYRKeyboardButtonStylePhone:
                {
					
					if ([self.button.input rangeOfCharacterFromSet:firstRowChar].location == NSNotFound)
					{
						[path rightArc:majorRadius turn:90]; // #1
						[path forward:(upperWidth - 2 * majorRadius) - 20]; // #2 top
						[path rightArc:majorRadius turn:90]; // #3
						
						[path forward:(CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom - 3) - 5]; // #4 right big
						
						[path rightArc:majorRadius turn:48];
						[path forward:8.5f];
						[path leftArc:majorRadius turn:48];
						
						[path forward:(CGRectGetHeight(keyRect) - minorRadius) - 20];
						
						[path rightArc:minorRadius turn:90];
						[path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
						[path rightArc:minorRadius turn:90];
						
						[path forward:(CGRectGetHeight(keyRect) - 2 * minorRadius) - 20];
						
						[path leftArc:majorRadius turn:90]; // #5
						[path forward:path.currentPoint.x - majorRadius];
						[path rightArc:majorRadius turn:90]; // #6
						
						offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(path.bounds) + insets.left;
						offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(path.bounds) + 10;
						
						[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
					}
					else
					{
						
						
						[path rightArc:majorRadius turn:90]; // #1
						[path forward:upperWidth - 2 * majorRadius]; // #2 top
						[path rightArc:majorRadius turn:90]; // #3
						[path forward:CGRectGetHeight(keyRect) - 2 * majorRadius + insets.top + insets.bottom - 3]; // #4 right big
						
						[path rightArc:majorRadius turn:48];
						[path forward:8.5f];
						[path leftArc:majorRadius turn:48];
						
						[path forward:CGRectGetHeight(keyRect) - minorRadius];
						[path rightArc:minorRadius turn:90];
						[path forward:lowerWidth - 2 * minorRadius]; //  lowerWidth - 2 * minorRadius + 0.5f
						[path rightArc:minorRadius turn:90];
						[path forward:CGRectGetHeight(keyRect) - 2 * minorRadius];
						
						[path leftArc:majorRadius turn:90]; // #5
						[path forward:path.currentPoint.x - majorRadius];
						[path rightArc:majorRadius turn:90]; // #6
						
						offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(path.bounds) + insets.left;
						offsetY = CGRectGetMaxY(keyRect) - CGRectGetHeight(path.bounds) + 10;
						
						[path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];

					}
					
					
                }
                    break;
					
                case CYRKeyboardButtonStyleTablet:
                {
                    CGRect firstRect = [self.inputOptionRects[0] CGRectValue];
					
                    path = (id)[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, CGRectGetWidth(firstRect) * self.button.inputOptions.count + 12, CGRectGetHeight(firstRect) + 12)
                                                          cornerRadius:6];
                    
                    offsetX = CGRectGetMaxX(keyRect) - CGRectGetWidth(path.bounds);
                    offsetY = CGRectGetMinY(firstRect) - 6;
                    
                    [path applyTransform:CGAffineTransformMakeTranslation(offsetX, offsetY)];
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        default:
            break;
    }
    
    return path;
}

- (void)determineExpandedKeyGeometries
{
    CGRect keyRect = [self convertRect:self.button.frame fromView:self.button.superview];
	
	if ([self.button.input rangeOfCharacterFromSet:firstRowChar].location == NSNotFound)
	{
		keyRect = CGRectMake(keyRect.origin.x, keyRect.origin.y + 22, keyRect.size.width -2 , keyRect.size.height );
	}
	
	
	NSString *optionChar = self.button.inputOptions[0];
	
//	CGSize stringSize = [optionChar sizeWithAttributes:@{NSFontAttributeName : self.button.inputOptionsFont}];
	
	CGSize stringSize = [optionChar sizeWithAttributes:@{NSFontAttributeName : self.button.inputOptionsFont}];
	
	if (optionChar.length > 1)
	{
		keyRect.size.width = stringSize.width - 5;
		
		if ([self isLandScapeOrientation])
		{
			int screenWidth = [UIScreen mainScreen].bounds.size.width;
			
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				NSLog(@"%f",keyRect.origin.x);
				
				if (keyRect.origin.x > 850)
				{
					keyRect.origin.x = keyRect.origin.x - 35;
				}
				keyRect.size.width = stringSize.width + 45;
			}
			else
			{
				if (screenWidth == 667)//iphone6
				{
					if(keyRect.origin.x == 519)
					{
						keyRect.origin.x = keyRect.origin.x + 8;  // url
					}
					else
					{
						keyRect.origin.x = keyRect.origin.x - 10;
					}
					
					
				}
				else if (screenWidth == 736)//iphone6p
				{
					if(keyRect.origin.x <= 577)
					{
						keyRect.origin.x = keyRect.origin.x + 11;  // url
					}
					else
					{
						keyRect.origin.x = keyRect.origin.x - 5;
					}
					//keyRect.origin.x = keyRect.origin.x - 5;
				}
				else if(screenWidth == 568) // iPhone 5
				{
					if(keyRect.origin.x >= 450)
					{
						keyRect.origin.x = keyRect.origin.x - 15;
					}
					else
					{
						keyRect.origin.x = keyRect.origin.x - 5;
					}
					
				}
				else if (screenWidth == 480)//iphone4
				{
					keyRect.origin.x = keyRect.origin.x - 18;
				}
			}
		}
		else
		{
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				
                if(keyRect.origin.x < 240 )
                {
                    keyRect.origin.x = keyRect.origin.x - 45;
                }
				else if (keyRect.origin.x > 628)
				{
					keyRect.origin.x = keyRect.origin.x - 25;
				}
                
				keyRect.size.width = stringSize.width + 20;
			}
		}
		
	}
	
    __block NSMutableArray *inputOptionRects = [NSMutableArray arrayWithCapacity:self.button.inputOptions.count];
	
    CGFloat offset = 0;
    CGFloat spacing = 0;
	
    __block CGRect optionRect = CGRectZero;
    
    switch (self.button.style) {
        case CYRKeyboardButtonStylePhone:
            offset = CGRectGetWidth(keyRect);
            spacing = 6;//6
            optionRect = CGRectOffset(CGRectInset(keyRect, 0, 0.5), 0, -(CGRectGetHeight(keyRect) + 15));
            break;
            
        case CYRKeyboardButtonStyleTablet:
            spacing = 0;
            optionRect = CGRectOffset(CGRectInset(keyRect, 6, 6), 0, -(CGRectGetHeight(keyRect) + 3));
            offset = CGRectGetWidth(optionRect);
            break;
            
        default:
            break;
    }
    
    [self.button.inputOptions enumerateObjectsUsingBlock:^(NSString *option, NSUInteger idx, BOOL *stop) {
		
		
		[inputOptionRects addObject:[NSValue valueWithCGRect:optionRect]];
		
		
        // Offset the option rect
        switch (_expandedPosition) {
            case CYRKeyboardButtonPositionRight:
                optionRect = CGRectOffset(optionRect, +(offset + spacing), 0);
                break;
                
            case CYRKeyboardButtonPositionLeft:
                optionRect = CGRectOffset(optionRect, -(offset + spacing), 0);
                break;
                
            default:
                break;
        }
    }];
    
    self.inputOptionRects = inputOptionRects;
}

-(BOOL)isLandScapeOrientation
{
	if([[UIScreen mainScreen] bounds].size.width < [[UIScreen mainScreen] bounds].size.height)
	{
		return NO;
	}
	
	return YES;
}

@end

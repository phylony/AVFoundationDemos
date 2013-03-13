//
//  MIT License
//
//  Copyright (c) 2013 Bob McCune http://bobmccune.com/
//  Copyright (c) 2013 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//

#import "THWaveformView.h"
#import "THSampleDataFilter.h"
#import "UIColor+THAdditions.h"
#import "UIView+THAdditions.h"

@interface THWaveformView ()
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@end

@implementation THWaveformView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
		_activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGFloat xPos = (self.frameWidth - _activityView.frameWidth) / 2;
		CGFloat yPos = (self.frameHeight - _activityView.frameHeight) / 2;
		_activityView.frame = CGRectMake(xPos, yPos, _activityView.frameWidth, _activityView.frameHeight);
		[self addSubview:_activityView];
		[_activityView startAnimating];
	}
	return self;
}

- (void)setSampleData:(NSData *)sampleData {
	if (_sampleData != sampleData) {
		[self.activityView stopAnimating];
		[self.activityView removeFromSuperview];
		_sampleData = sampleData;
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	// Draw rounded rect gradient background
	CGContextSaveGState(context);

	UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8, 8)];
	CGContextAddPath(context, roundedPath.CGPath);
	CGContextClip(context);

	// Define Colors
	UIColor *bgStartColor = self.trackColor.lighterColor;
	UIColor *bgEndColor = self.trackColor.darkerColor;
	NSArray *bgColors = @[(__bridge id)bgStartColor.CGColor, (__bridge id)bgEndColor.CGColor];

	// Define Color Locations
	CGFloat bgLocations[] = {0.0, 1.0};

	// Create Gradient

	CGGradientRef bgGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)bgColors, bgLocations);

	// Define start and end points and draw gradient
	CGPoint bgStartPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint bgEndPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));

	CGContextDrawLinearGradient(context, bgGradient, bgStartPoint, bgEndPoint, 0);

	CGGradientRelease(bgGradient);
	CGContextRestoreGState(context);

	// Draw waveforms
	CGContextSaveGState(context);
	CGContextScaleCTM(context, 0.95, 0.90);
	CGFloat xOffset = self.bounds.size.width - (self.bounds.size.width * 0.95);
	CGFloat yOffset = self.bounds.size.height - (self.bounds.size.height * 0.90);
	CGContextTranslateCTM(context, xOffset / 2, yOffset / 2);

	THSampleDataFilter *filter = [[THSampleDataFilter alloc] initWithData:self.sampleData];
	NSArray *filteredSamples = [filter filteredSamplesForSize:self.bounds.size];

	CGFloat midY = CGRectGetMidY(rect);

	CGMutablePathRef halfPath = CGPathCreateMutable();
	CGPathMoveToPoint(halfPath, NULL, 0.0f, midY);

	for (NSUInteger i = 0; i < filteredSamples.count; i++) {
		float sample = [filteredSamples[i] floatValue];
		CGPathAddLineToPoint(halfPath, NULL, i, midY - sample);
	}

	CGPathAddLineToPoint(halfPath, NULL, filteredSamples.count, midY);

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddPath(path, NULL, halfPath);

	CGAffineTransform transform = CGAffineTransformIdentity;
	transform = CGAffineTransformTranslate(transform, 0, CGRectGetHeight(rect));
	transform = CGAffineTransformScale(transform, 1.0, -1.0);
	CGPathAddPath(path, &transform, halfPath);

	CGContextAddPath(context, path);
	CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.502 alpha:.5].CGColor);
	CGContextStrokePath(context);

	// Define Colors
	UIColor *startColor = [UIColor colorWithWhite:0.941 alpha:.8];
	UIColor *endColor = [UIColor colorWithWhite:0.878 alpha:.8];
	NSArray *colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];

	// Define Color Locations
	CGFloat locations[] = {0.0, 1.0};

	// Create Gradient
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);

	// Define start and end points and draw gradient
	CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));

	CGContextSetBlendMode(context, kCGBlendModeScreen);

	CGContextAddPath(context, path);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

	CGContextRestoreGState(context);

	// Created them need to release them
	CGPathRelease(halfPath);
	CGPathRelease(path);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);

	// Draw shine layer over top
	CGContextScaleCTM(context, 1.0, 1.0);
	CGRect shineRect = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect) / 2);
	CGPathRef highlightPath = [UIBezierPath bezierPathWithRoundedRect:shineRect
	                                                byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
					                                      cornerRadii:CGSizeMake(8.0f, 8.0f)].CGPath;
	CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.100].CGColor);
	CGContextAddPath(context, highlightPath);
	CGContextFillPath(context);
}

@end

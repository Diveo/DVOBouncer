//
//  DVOBouncer.h
//  Diveo
//
//  Created by Mo Bitar on 4/1/14.
//  Copyright (c) 2014 Diveo Co. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DVOBounceDirection)
{
    DVOBounceDirectionBottom,
    DVOBounceDirectionTop,
    DVOBounceDirectionLeft,
    DVOBounceDirectionRight
};

@interface DVOBouncer : NSObject

- (instancetype)initWithView:(UIView *)view NS_DESIGNATED_INITIALIZER;

@property (nonatomic) UIView *viewToBounce;

/* Default is 1.75. Gravity behavior is a bit strange - does not reach all the way to bottom for some reason */
@property (nonatomic) CGFloat boundaryOffset;

@property (nonatomic) DVOBounceDirection bounceDirection;

/** the peak of the bounce animation. default is 100 */
@property (nonatomic) CGFloat bouncePeak;

- (void)beginBouncing;

- (void)endBouncing;

@end

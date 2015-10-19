//
//  DVOBouncer.m
//  Diveo
//
//  Created by Mo Bitar on 4/1/14.
//  Copyright (c) 2014 Diveo Co. All rights reserved.
//

#import "DVOBouncer.h"

BOOL BounceDirectionIsVertical(DVOBounceDirection direction)
{
    return direction == DVOBounceDirectionTop || direction == DVOBounceDirectionBottom;
}

CGPoint BounceOffset(CGPoint currentOffset, CGFloat delta, DVOBounceDirection direction)
{
    if(BounceDirectionIsVertical(direction)) {
        if(direction == DVOBounceDirectionBottom) {
            return CGPointMake(currentOffset.x, currentOffset.y - delta);
        } else {
            return CGPointMake(currentOffset.x, currentOffset.y + delta);
        }
    } else {
        if(direction == DVOBounceDirectionLeft) {
            return CGPointMake(currentOffset.x + delta, currentOffset.y);
        } else {
            return CGPointMake(currentOffset.x - delta, currentOffset.y);
        }
    }
}

DVOBounceDirection OppositeDirection(DVOBounceDirection direction)
{
    switch (direction) {
        case DVOBounceDirectionBottom:
            return DVOBounceDirectionTop;
        case DVOBounceDirectionTop:
            return DVOBounceDirectionBottom;
        case DVOBounceDirectionLeft:
            return DVOBounceDirectionRight;
        case DVOBounceDirectionRight:
            return DVOBounceDirectionLeft;
    }
}


@interface DVOBounceItem : NSObject <UIDynamicItem>
@property (nonatomic) UIView *viewToBounce;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) DVOBounceDirection direction;
@property (nonatomic) BOOL endBouncing;
@end

@implementation DVOBounceItem
{
    CGPoint previousCenter;
}

- (void)setCenter:(CGPoint)center
{
    _center = center;
    
    if(self.endBouncing) {
        return;
    }
    
    CGFloat delta = center.y - previousCenter.y;

    if([self.viewToBounce isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.viewToBounce;
        scrollView.contentOffset = BounceOffset(scrollView.contentOffset, delta, self.direction);
    } else {
        CGRect frame = self.viewToBounce.frame;
        frame.origin = BounceOffset(frame.origin, delta, self.direction);
        self.viewToBounce.frame = frame;
    }
    
    previousCenter = center;
}

@end

@interface DVOBouncer () <UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate>
@property (nonatomic) UIDynamicAnimator *animator;
@property (nonatomic) DVOBounceItem *item;
@property (nonatomic) CGPoint previousVelocity;
@end

@implementation DVOBouncer
{
    CGPoint initialOrigin;
    BOOL endBouncing;
}

- (instancetype)initWithView:(UIView *)view
{
    if(self = [super init]) {
        self.viewToBounce = view;
        _boundaryOffset = 0;
        _bouncePeak = 100;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)beginBouncing
{
    CGFloat itemSize = 50;
    DVOBounceItem *item = [DVOBounceItem new];
    item.bounds = CGRectMake(0, 0, itemSize, itemSize);
    item.center = CGPointMake(0, self.viewToBounce.bounds.size.height - self.bouncePeak - itemSize/2.0);
    item.direction = self.bounceDirection;
    self.item = item;
    
    item.viewToBounce = self.viewToBounce;
    
    if(!self.animator) {
        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:nil];
        self.animator.delegate = self;
    } else {
        [self.animator removeAllBehaviors];
    }
    
    initialOrigin = self.viewToBounce.frame.origin;
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:nil];
    gravity.magnitude = 1;
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:nil];
    collision.collisionDelegate = self;
    
    [collision addBoundaryWithIdentifier:@"bottom"
                               fromPoint:CGPointMake(0, self.viewToBounce.frame.origin.y + self.viewToBounce.bounds.size.height + self.boundaryOffset)
                                 toPoint:CGPointMake(0, self.viewToBounce.frame.origin.y + self.viewToBounce.bounds.size.height + self.boundaryOffset)];
    
    UIDynamicItemBehavior *bounce = [[UIDynamicItemBehavior alloc] initWithItems:nil];
    bounce.elasticity = 0.6;
    
    [self.animator addBehavior:collision];
    [self.animator addBehavior:gravity];
    [self.animator addBehavior:bounce];
    
    UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[item]];
    __weak UIDynamicItemBehavior *weakBehavior = dynamicItemBehavior;
    __weak typeof(self) weakself = self;
    dynamicItemBehavior.action = ^{
        CGPoint velocity = [weakBehavior linearVelocityForItem:item];
        if(fabs(velocity.y) < 0.00000005 && fabs(weakself.previousVelocity.y) > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself restoreInitialViewState];
            });
        }
        weakself.previousVelocity = velocity;
    };
    [self.animator addBehavior:dynamicItemBehavior];
    
    // animate initial offset
    [UIView animateWithDuration:0.3 animations:^{
        if([self.viewToBounce isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)self.viewToBounce;
            [scrollView setContentOffset:BounceOffset(scrollView.contentOffset, -self.bouncePeak, self.bounceDirection)];
        } else {
            CGRect frame = self.viewToBounce.frame;
            frame.origin = BounceOffset(frame.origin, -self.bouncePeak, self.bounceDirection);
            self.viewToBounce.frame = frame;
        }
    } completion:^(BOOL finished) {
        if(endBouncing) {
            return;
        }
        [collision addItem:item];
        [gravity addItem:item];
        [bounce addItem:item];
    }];
}

#pragma clang diagnostic pop

- (void)restoreInitialViewState
{
    if([self.viewToBounce isKindOfClass:[UIScrollView class]]) {
        [(UIScrollView *)self.viewToBounce setContentOffset:initialOrigin animated:NO];
    } else {
        CGRect frame = self.viewToBounce.frame;
        frame.origin = initialOrigin;
        self.viewToBounce.frame = frame;
    }
}

- (void)endBouncing
{
    endBouncing = YES;
    self.item.endBouncing = YES;
    [self.animator removeAllBehaviors];
}

#pragma mark - Animator Delegate

- (void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(!endBouncing) {
            [self beginBouncing];
        }
    });
}

@end

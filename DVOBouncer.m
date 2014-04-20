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
@property (nonatomic) UIScrollView *scrollView;
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

    self.scrollView.contentOffset = BounceOffset(self.scrollView.contentOffset, delta, self.direction);;
    
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
    CGPoint initialScrollViewOffset;
    BOOL endBouncing;
}

+ (instancetype)sharedInstance
{
    static DVOBouncer *bouncer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bouncer = [DVOBouncer new];
    });
    
    return bouncer;
}

- (instancetype)init
{
    if(self = [super init]) {
        _boundaryOffset = 0;
        _bouncePeak = 100;
    }
    return self;
}

+ (instancetype)bounceScrollView:(UIScrollView *)scrollView inDirection:(DVOBounceDirection)direction bouncePeak:(CGFloat)bouncePeak
{
    DVOBouncer *bouncer = [DVOBouncer new];
    bouncer.scrollView = scrollView;
    bouncer.bounceDirection = direction;
    bouncer.bouncePeak = bouncePeak;
    [bouncer beginBouncing];
    return bouncer;
}

+ (instancetype)bounceScrollView:(UIScrollView *)scrollView inDirection:(DVOBounceDirection)direction
{
    DVOBouncer *bouncer = [DVOBouncer new];
    bouncer.scrollView = scrollView;
    bouncer.bounceDirection = direction;
    [bouncer beginBouncing];
    return bouncer;
}

- (void)beginBouncing
{
    CGFloat itemSize = 50;
    DVOBounceItem *item = [DVOBounceItem new];
    item.bounds = CGRectMake(0, 0, itemSize, itemSize);
    item.center = CGPointMake(0, self.scrollView.bounds.size.height - self.bouncePeak - itemSize/2.0);
    item.direction = self.bounceDirection;
    self.item = item;
    
    item.scrollView = self.scrollView;
    self.scrollView = self.scrollView;
    
    if(!self.animator) {
        self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:nil];
        self.animator.delegate = self;
    } else {
        [self.animator removeAllBehaviors];
    }
    
    initialScrollViewOffset = self.scrollView.contentOffset;
    
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:nil];
    gravity.magnitude = 1;
    
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:nil];
    collision.collisionDelegate = self;
    
    [collision addBoundaryWithIdentifier:@"bottom"
                               fromPoint:CGPointMake(0, self.scrollView.frame.origin.y + self.scrollView.bounds.size.height + self.boundaryOffset)
                                 toPoint:CGPointMake(0, self.scrollView.frame.origin.y + self.scrollView.bounds.size.height + self.boundaryOffset)];
    
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
                [weakself restoreScrollViewState];
            });
        }
        weakself.previousVelocity = velocity;
    };
    [self.animator addBehavior:dynamicItemBehavior];
    
    // animate initial offset
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollView.contentOffset = BounceOffset(self.scrollView.contentOffset, -self.bouncePeak, self.bounceDirection);
    } completion:^(BOOL finished) {
        if(endBouncing) {
            return;
        }
        [collision addItem:item];
        [gravity addItem:item];
        [bounce addItem:item];
    }];
}

- (void)restoreScrollViewState
{
    [self.scrollView setContentOffset:initialScrollViewOffset animated:NO];
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

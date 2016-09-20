//
//  _GLImageZoomer.m
//  galenlin
//
//  Created by galen on 15/9/6.
//  Copyright © 2015年 wequick. All rights reserved.
//

#import "_GLImageZoomer.h"
#import "UIImageView+WebCache.h"

@interface _GLImageZoomer () <UIScrollViewDelegate>
{
    UIImageView *_zoomImageView;
    CAShapeLayer *_progressLayer;

    struct {
        unsigned int needsResetInsets : 1;
        unsigned int loaded : 1;
        unsigned int loading : 1;
        unsigned int needsReload : 1;
    } _flags;
    
    CGRect _imageRect;
}

@end

@implementation _GLImageZoomer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setDelegate:self];
        [self setMinimumZoomScale:1];
        [self setMaximumZoomScale:2];
        
        // Subviews
        CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        
        CGFloat width = 40.f;
        CAShapeLayer *progressLayer = [[CAShapeLayer alloc] init];
        progressLayer.bounds = CGRectMake(0, 0, width, width);
        progressLayer.position = center;
        progressLayer.backgroundColor = [UIColor blackColor].CGColor;
        progressLayer.cornerRadius = width / 2;
        progressLayer.strokeColor = [UIColor whiteColor].CGColor;
        progressLayer.fillColor = [UIColor clearColor].CGColor;
        progressLayer.lineWidth = 4.f;
        progressLayer.lineCap = kCALineCapRound;
        progressLayer.lineJoin = kCALineJoinRound;
        progressLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width/2, width/2) radius:width/2-6 startAngle:-M_PI_2 endAngle:3*M_PI_2 clockwise:YES].CGPath;
        progressLayer.hidden = YES;
        progressLayer.strokeEnd = 0;
        progressLayer.zPosition = 100;
        [self.layer addSublayer:progressLayer];
        
        _progressLayer = progressLayer;
    }
    return self;
}

- (void)reloadData {
    _flags.needsReload = 1;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!_flags.needsReload) {
        return;
    }
    
    if (_flags.loading || _flags.loaded) {
        return;
    }
    
    if (self.imageURL == nil) {
        return;
    }
    
//    [self initZoomImageView];
    _flags.loading = 1;
    
    // Show progress layer
    _progressLayer.hidden = NO;
    _progressLayer.strokeEnd = .01f;
    [self setMaximumZoomScale:1];
    
    // Load image from URL
    NSLog(@"-- load for %i", (int)[self.superview.subviews indexOfObject:self]);
    [_zoomImageView sd_setImageWithURL:self.imageURL placeholderImage:self.placeholderImage options:SDWebImageProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if (expectedSize > 0) {
            CGFloat percent = (float)receivedSize / (float)expectedSize;
            if (percent > _progressLayer.strokeEnd) {
                _progressLayer.strokeEnd = percent;
            }
        }
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        _flags.loaded = 1;
        _flags.loading = 0;
        _progressLayer.hidden = YES;
        [self setMaximumZoomScale:2];
        [self __adjustContentSize];
    }];
}

- (void)setImageURL:(NSURL *)imageURL {
    _imageURL = imageURL;
    if (imageURL != nil) {
        BOOL hasCacheImage = [[SDWebImageManager sharedManager] diskImageExistsForURL:self.imageURL];
        if (hasCacheImage) {
            _flags.loaded = 1;
            NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.imageURL];
            self.placeholderImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
        }
    }
    [self initZoomImageView];
}

- (void)initZoomImageView {
    if (_zoomImageView != nil) {
        return;
    }
    
    NSLog(@"-- init for %i", (int)[self.superview.subviews indexOfObject:self]);
    
    if (self.placeholderImage == nil) {
        CGSize size = _initialSize;
        if (CGSizeEqualToSize(size, CGSizeZero)) {
            size = CGSizeMake(self.bounds.size.width, self.bounds.size.width);
        }
        _zoomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    } else {
        _zoomImageView = [[UIImageView alloc] initWithImage:self.placeholderImage];
    }
    [_zoomImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_zoomImageView setBackgroundColor:[UIColor whiteColor]];
    [self insertSubview:_zoomImageView atIndex:0];
    [self __adjustContentSize];
}

#pragma mark - Properties

- (UIImage *)image {
    return _zoomImageView.image;
}

- (CGRect)imageRect {
    [self initZoomImageView];
    
    CGRect frame = self.bounds;
    CGRect imageRect = [_zoomImageView frame];
    if (imageRect.size.width == 0) {
        UIImage *image = _zoomImageView.image ?: self.placeholderImage;
        if (image == nil) {
            return CGRectZero;
        }
        imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    }
    
    if (imageRect.size.width != frame.size.width) {
        imageRect.size.height = imageRect.size.height * frame.size.width / imageRect.size.width;
        imageRect.size.width = frame.size.width;
    }
    imageRect.origin.x = 0;
    imageRect.origin.y = (frame.size.height - imageRect.size.height) / 2;
    
    return imageRect;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(nonnull UIScrollView *)scrollView {
    return _zoomImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (_flags.needsResetInsets == 0) {
        return;
    }
    
    UIView *view = _zoomImageView;
    CGFloat top, bottom;
    if (view.frame.size.height < self.visualRect.size.height) {
        top = -(view.frame.size.height - _imageRect.size.height) / 2;
        bottom = self.visualRect.origin.y + _imageRect.origin.y + top;
    } else {
        top = self.visualRect.origin.y - _imageRect.origin.y;
        bottom = self.visualRect.origin.y + _imageRect.origin.y;
    }
    [scrollView setContentInset:UIEdgeInsetsMake(top, self.visualRect.origin.x, bottom, self.visualRect.origin.x)];
}

#pragma mark - Private

- (void)__adjustContentSize {
    UIImageView *imageView = _zoomImageView;
    UIScrollView *scrollView = self;
    
    CGRect frame = self.visualRect;
    if (CGRectEqualToRect(frame, CGRectZero)) {
        frame = [self bounds];
        self.visualRect = frame;
    }
    CGFloat top, bottom;
    CGRect circleRect = frame;
    CGRect imageRect = [self imageRect];
    if (imageRect.size.height < circleRect.size.height) {
        top = 0;
        bottom = 2 * circleRect.origin.y;
        _flags.needsResetInsets = YES;
    } else {
        top = circleRect.origin.y - imageRect.origin.y;
        bottom = circleRect.origin.y + imageRect.origin.y;
    }
    [scrollView setContentSize:imageRect.size];
    [scrollView setContentInset:UIEdgeInsetsMake(top, frame.origin.x, bottom, frame.origin.x)];
    _imageRect = imageRect;
    
    [imageView setFrame:imageRect];
}

@end

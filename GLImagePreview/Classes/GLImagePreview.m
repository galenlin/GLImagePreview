//
//  GLImagePreview.m
//  galenlin
//
//  Created by galen on 15/9/6.
//  Copyright © 2015年 wequick. All rights reserved.
//

#import "GLImagePreview.h"
#import "_GLImageZoomer.h"
#import "MBProgressHUD.h"

@interface GLImagePreview () <UIGestureRecognizerDelegate, UIScrollViewDelegate>

@end

@implementation GLImagePreview

static const NSInteger kConcurrentLoadOffset = 1; // The nearby slides with the offset will be concurrently load
static const CGFloat kGutterWidth = 16.f; // The gutter between slides

+ (void)preview:(id<GLImagePreviewDelegate>)delegate count:(NSInteger)count index:(NSInteger)index
{
    GLImagePreview *preview = [[self alloc] init];
    preview->_delegate = delegate;
    preview->_currentImageIndex = index;
    preview->_imageCount = count;
    [preview show];
}

- (instancetype)init
{
    if (self = [super init]) {
        [self setBackgroundColor:[UIColor blackColor]];
        
        // Subviews
        _sliderView = [[UIScrollView alloc] init];
        [_sliderView setBackgroundColor:[UIColor clearColor]];
        [_sliderView setPagingEnabled:YES];
        [_sliderView setDelegate:self];
        [self addSubview:_sliderView];
        
        _dumpImageView = [[UIImageView alloc] init];
        [_dumpImageView setContentMode:UIViewContentModeScaleAspectFill];
        [_dumpImageView setAutoresizingMask:UIViewAutoresizingNone];
        [_dumpImageView setClipsToBounds:YES];
        [self addSubview:_dumpImageView];
        
        // Gestures
        UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
        tapper.delaysTouchesBegan = YES;
        tapper.delegate = self;
        [self addGestureRecognizer:tapper];
        _hideViewTapper = tapper;
    }
    return self;
}

- (void)show
{
    UIImageView *currentSourceView = [_delegate preview:self imageViewForIndex:_currentImageIndex];
    if (currentSourceView.image == nil) {
        NSLog(@"GLImagePreview: current image is nil! (index = %d)", (int)_currentImageIndex);
        return;
    }
    
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    CGSize contentSize = window.bounds.size;
    [self setFrame:window.bounds];
    [window addSubview:self];
    
    // Add gutter between slides, refer to http://stackoverflow.com/questions/12361519/how-to-create-a-paging-scrollview-with-space-between-views
    CGFloat widthWithGutter = contentSize.width + kGutterWidth;
    CGRect frameWithGutter = CGRectMake(0, 0, widthWithGutter, contentSize.height);
    [_sliderView setFrame:frameWithGutter];
    
    // Add photo views
    UIImageView *currentImageView;
    _GLImageZoomer *currentPhotoView;
    CGRect subviewFrame = self.bounds;
    for (NSInteger index = 0; index < _imageCount; index++) {
        _GLImageZoomer *photoView = nil;
        BOOL isCurrent = (index == _currentImageIndex);
        UIImageView *sourceView = isCurrent ? currentSourceView : [_delegate preview:self imageViewForIndex:index];
        photoView = [[_GLImageZoomer alloc] initWithFrame:subviewFrame];
        [_sliderView addSubview:photoView];
        
        NSURL *sourceURL = [_delegate preview:self highQualityImageURLForIndex:index];
        [photoView setInitialSize:sourceView.bounds.size];
        [photoView setPlaceholderImage:sourceView.image];
        [photoView setImageURL:sourceURL];
        
        // FIXME: Prevent tap gesture from photo view
        for (UIGestureRecognizer *recognizer in photoView.gestureRecognizers) {
            [_hideViewTapper requireGestureRecognizerToFail:recognizer];
        }
        
        if (abs((int)index - (int)_currentImageIndex) <= kConcurrentLoadOffset) {
            [photoView reloadData];
        }
        
        subviewFrame.origin.x += widthWithGutter;
        
        if (isCurrent) {
            currentImageView = sourceView;
            currentPhotoView = photoView;
        }
    }
    [_sliderView setContentSize:CGSizeMake(subviewFrame.origin.x, subviewFrame.size.height)];
    [_sliderView setContentOffset:CGPointMake(_currentImageIndex * widthWithGutter, 0)];
    
    // Animate current photo
    [_sliderView setHidden:YES];
    UIImageView *srcView = currentImageView;
    CGRect srcRect = [srcView convertRect:srcView.bounds toView:self];
    [_dumpImageView setFrame:srcRect];
    [_dumpImageView setImage:srcView.image];
    
    CGRect dstRect = [currentPhotoView imageRect];
    if (CGRectEqualToRect(dstRect, CGRectZero)) {
        dstRect.size = srcRect.size;
        dstRect.origin.x = (subviewFrame.size.width - dstRect.size.width) / 2;
        dstRect.origin.y = (subviewFrame.size.height - dstRect.size.height) / 2;
    }
    
    [currentPhotoView setNeedsDisplay];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [UIView animateWithDuration:.25 delay:0 options:0 animations:^{
        [_dumpImageView setFrame:dstRect];
    } completion:^(BOOL finished) {
        [_sliderView setHidden:NO];
        [_dumpImageView setHidden:YES];
        [self initToolbar];
    }];
}

- (void)hide {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    for (UIView *subview in self.subviews) {
        if (![subview isEqual:_dumpImageView]) {
            [subview removeFromSuperview];
        }
    }
    [self setBackgroundColor:[UIColor clearColor]];
    
    UIImageView *srcView = [_delegate preview:self imageViewForIndex:_currentImageIndex];
    CGRect srcRect = [srcView convertRect:srcView.bounds toView:self];
    [_dumpImageView setImage:srcView.image];
    [_dumpImageView setHidden:NO];
    BOOL srcHidden = srcView.hidden;
    [srcView setHidden:YES];
    [UIView animateWithDuration:.25 delay:0 options:7<<16 animations:^{
        [_dumpImageView setFrame:srcRect];
    } completion:^(BOOL finished) {
        _titleLabel = nil;
        _hideViewTapper = nil;
        _dumpImageView = nil;
        _sliderView = nil;
        if ([_delegate respondsToSelector:@selector(previewDidHide:)]) {
            [_delegate previewDidHide:self];
        }
        _delegate = nil;
        [srcView setHidden:srcHidden];
        [self removeFromSuperview];
    }];
}

- (void)initToolbar {
    // 序标
    if (_imageCount > 1) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:18];
        titleLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:.4];
        titleLabel.layer.cornerRadius = 16;
        titleLabel.clipsToBounds = YES;
        titleLabel.text = [NSString stringWithFormat:@"%d/%ld", (int)_currentImageIndex+1, (long)_imageCount];
        [self addSubview:titleLabel];
        
        _titleLabel = titleLabel;
        
        [titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSDictionary *views = @{@"title":_titleLabel};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[title(==80)]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[title(==32)]" options:0 metrics:nil views:views]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:titleLabel attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    }
    
    // 保存按钮
    UIButton *saveButton = [[UIButton alloc] init];
    [saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    saveButton.backgroundColor = [UIColor colorWithWhite:0 alpha:.4];
    saveButton.layer.cornerRadius = 2;
    saveButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:.4].CGColor;
    saveButton.layer.borderWidth = .5f;
    saveButton.clipsToBounds = YES;
    [saveButton addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:saveButton];
    
    [saveButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSDictionary *views = @{@"save":saveButton};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-16-[save(==52)]" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[save(==32)]-12-|" options:0 metrics:nil views:views]];
}

- (void)saveImage
{
    _GLImageZoomer *photoView = [[_sliderView subviews] objectAtIndex:_currentImageIndex];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    hud.label.text = @"保存中...";
    [hud showAnimated:YES];
    UIImageWriteToSavedPhotosAlbum(photoView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    NSString *tips;
    if (error) {
        tips = @"保存失败";
    } else {
        tips = @"保存成功";
    }
    [MBProgressHUD hideHUDForView:self.window animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = tips;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1.f];
}

#pragma mark - Gesture

- (void)tapHandler:(UITapGestureRecognizer *)tapper {
    [self hide];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(nonnull UIScrollView *)scrollView {
    if (_titleLabel != nil) {
        NSInteger newImageIndex = scrollView.contentOffset.x / scrollView.bounds.size.width + .5f;
        _titleLabel.text = [NSString stringWithFormat:@"%d/%d", (int)newImageIndex+1, (int)_imageCount];
    }
}

- (void)scrollViewDidEndDecelerating:(nonnull UIScrollView *)scrollView {
    NSInteger newImageIndex = (int)(scrollView.contentOffset.x / scrollView.bounds.size.width);
    if (newImageIndex != _currentImageIndex) {
        // Reload
        _GLImageZoomer *photoView = [[scrollView subviews] objectAtIndex:_currentImageIndex];
        [photoView setZoomScale:1];
        
        // Lazy init nearby photo views
        NSInteger minIndex = MAX(newImageIndex - kConcurrentLoadOffset, 0);
        NSInteger maxIndex = MIN(newImageIndex + kConcurrentLoadOffset, _imageCount - 1);
        for (NSInteger index = minIndex; index <= maxIndex; index++) {
            if (index == _currentImageIndex) {
                continue;
            }
            photoView = [[_sliderView subviews] objectAtIndex:index];
            [photoView reloadData];
        }
        
        _currentImageIndex = newImageIndex;
    }
}

@end

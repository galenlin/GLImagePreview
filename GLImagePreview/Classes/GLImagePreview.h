//
//  GLImagePreview.h
//  Wequick
//
//  Created by galen on 15/9/6.
//  Copyright © 2015年 wequick. All rights reserved.
//

#import <UIKit/UIKit.h>

//______________________________________________________________________________

@class GLImagePreview;

@protocol GLImagePreviewDelegate <NSObject>

@required

/**
 The imageView at the index.
 
 @discussion We use the imageView to do these:
 
 * Get the source image to show a placeholder image.
 * Get the source rect for animate zoom-in and zoom-out.
 
 */
- (UIImageView *)preview:(GLImagePreview *)preview imageViewForIndex:(NSInteger)index;

/**
 The high quality image URL at the index.
 */
- (NSURL *)preview:(GLImagePreview *)preview highQualityImageURLForIndex:(NSInteger)index;

@optional

- (void)previewDidHide:(GLImagePreview *)preview;

@end

//______________________________________________________________________________

/**
 An instance of GLImagePreview displays a set of images by GLImagePreviewDelegate.
 
 Example:
 
     - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
         [GLImagePreview preview:self count:imageCount index:indexPath.row];
     }
 
 */
@interface GLImagePreview : UIView
{
    UIImageView *_dumpImageView;
    UIScrollView *_sliderView;
    UITapGestureRecognizer *_hideViewTapper;
    UILabel *_titleLabel;
    NSInteger _currentImageIndex;
    NSInteger _imageCount;
    __unsafe_unretained id<GLImagePreviewDelegate> _delegate;
}

+ (void)preview:(id<GLImagePreviewDelegate>)delegate count:(NSInteger)count index:(NSInteger)index;

@end

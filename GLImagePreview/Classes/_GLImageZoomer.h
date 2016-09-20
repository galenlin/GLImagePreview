//
//  _GLImageZoomer.h
//  galenlin
//
//  Created by galen on 15/9/6.
//  Copyright © 2015年 wequick. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface _GLImageZoomer : UIScrollView

@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, assign) CGSize initialSize;
@property (nonatomic, assign) CGRect visualRect;

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, assign, readonly) CGRect imageRect;

- (void)reloadData;

@end

//
//  GLViewController.m
//  GLImagePreview
//
//  Created by galenlin on 09/19/2016.
//  Copyright (c) 2016 galenlin. All rights reserved.
//

#import "GLViewController.h"
#import "UIImageView+WebCache.h"
#import "GLImagePreview.h"

@interface GLViewController () <GLImagePreviewDelegate>

@end

@implementation GLViewController

static NSString *const kThumbnailUrl = @"https://placeholdit.imgix.net/~text?txtsize=60&bg=78b8fc&txtclr=f0f0f0&txt=G&w=120&h=120&txttrack=0";
static NSString *const kLargeUrl = @"https://placeholdit.imgix.net/~text?txtsize=240&bg=78b8fc&txtclr=f0f0f0&txt=G&w=480&h=480&txttrack=0";
static int kCellCount = 10;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kCellCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ImageCell"];
    UIImageView *thumbnail = [cell viewWithTag:1];
    [thumbnail setBackgroundColor:[UIColor colorWithRed:(1.0 * 0x78 / 0xff) green:(1.0 * 0xb8 / 0xff) blue:(1.0 * 0xfc / 0xff) alpha:1]];
    NSString *url = [NSString stringWithFormat:@"https://placeholdit.imgix.net/~text?txtsize=48&bg=78b8fc&txtclr=f0f0f0&w=120&h=120&txttrack=0&txt=%i", (int)[indexPath row]];
    [thumbnail sd_setImageWithURL:[NSURL URLWithString:url] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [thumbnail setBackgroundColor:nil];
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [GLImagePreview preview:self count:kCellCount index:indexPath.row];
}

#pragma mark - Preview Delegate

- (UIImageView *)preview:(GLImagePreview *)preview imageViewForIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil) {
        return nil;
    }
    return [cell viewWithTag:1];
}

- (NSURL *)preview:(GLImagePreview *)preview highQualityImageURLForIndex:(NSInteger)index {
    NSString *url = [NSString stringWithFormat:@"https://placeholdit.imgix.net/~text?txtsize=128&bg=78b8fc&txtclr=f0f0f0&w=320&h=320&txttrack=0&txt=%i", (int)index];
    return [NSURL URLWithString:url];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

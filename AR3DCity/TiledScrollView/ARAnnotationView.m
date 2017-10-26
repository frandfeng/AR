//
//  ARAnnotationView.m
//  AR3DCity
//
//  Created by frandfeng on 23/10/2017.
//  Copyright © 2017 JingHeQianCheng. All rights reserved.
//

#import "ARAnnotationView.h"

@interface ARAnnotationView()

@end

@implementation ARAnnotationView

- (instancetype)initWithFrame:(CGRect)frame annotation:(id<JCAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithFrame:frame annotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupImageView];
        [self setupLabel];
    }
    return self;
}

- (void)setupImageView {
    _imageView = [[UIImageView alloc] init];
    [self addSubview:_imageView];
}

- (void)setupLabel {
    _label = [[UILabel alloc] init];
    [self addSubview:_label];
}

- (CGSize)sizeThatFits:(CGSize)size {
    UIImageView *imageView = _imageView;
    if (imageView!=nil && imageView.image!=nil) {
        return imageView.image.size;
    }
    return CGSizeMake(30, 30);
}

- (void)layoutSubviews {
    UIImageView *imageView = _imageView;
    [imageView sizeToFit];
    [imageView setFrame:CGRectMake(0, 0, imageView.frame.size.width, imageView.frame.size.height)];
    UILabel *label = _label;
    [label setFrame:CGRectMake(0, 0,imageView.frame.size.width, imageView.frame.size.height)];
}

@end

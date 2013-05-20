//
//  PagingPage.m
//  testScrollview
//
//  Created by 苏 孝禹 on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PagingPage.h"

@interface PagingPage()
@property (nonatomic,retain) UIImageView *imageView;

@end


@implementation PagingPage
@synthesize imageName = _imageName;
@synthesize imageView = _imageView;


- (void)dealloc{
    [_imageView release];
    [super dealloc];
}

- (void)layoutSubviews{
    
    
    
    if (self.frame.size.width > 768) {
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
    }else{
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    
    
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.imageView = [[[UIImageView alloc]initWithFrame:self.bounds ] autorelease];
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];
    }
    return self;
}


- (void)setImageName:(NSString *)imageName{
    _imageName = imageName;
    NSString *getImageName = [[NSBundle mainBundle]pathForResource:imageName ofType:@"jpg" ];
    UIImage *image = [[UIImage alloc]initWithContentsOfFile:getImageName ];
    self.imageView.image = image;
    [image release];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

//
//  testScrollviewViewController.m
//  testScrollview
//
//  Created by 苏 孝禹 on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "testScrollviewViewController.h"
#import "PagingView.h"
#import "PagingPage.h"
@interface testScrollviewViewController()<ScrollViewDataSource,ScrollViewDelegate> 
@property (nonatomic,retain) PagingView *scrollView;
@property (nonatomic,retain) NSMutableArray *array;


@end

@implementation testScrollviewViewController
@synthesize scrollView = _scrollView;
@synthesize array = _array;


- (void)dealloc{
    [_scrollView release];
    [_array release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.array = [NSMutableArray array];
    for (unsigned i =101; i < 117; i ++) {
        NSString *imageName = [[[NSString alloc]initWithFormat:@"%d",i] autorelease];
        [self.array addObject:imageName];
    }
    
    
    UIView *view1 = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:view1];
    
    UIView *view2 = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:view2];

    UIView *view3 = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:view3];

    UIView *view4 = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:view4];

    UIView *view5 = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:view5];

    NSLog(@"viewCount: %d",self.view.subviews.count);
    NSLog(@"%d",[self.view.subviews indexOfObject:view1]);
    [self.view  insertSubview:view1 belowSubview:view5];
    
        NSLog(@"viewCount: %d",self.view.subviews.count);
     NSLog(@"%d",[self.view.subviews indexOfObject:view1]);
    
	// Do any additional setup after loading the view, typically from a nib.
    self.scrollView = [[[PagingView alloc]initWithFrame:self.view.bounds ] autorelease];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.direction = ScrollViewDirectionHorizontal;
    self.scrollView.scrollviewDataSource = self;
    self.scrollView.scrollviewDelegate = self;
    self.scrollView.pagePadding = 0;
    [self.view addSubview:self.scrollView];
}


#pragma mark -
#pragma mark PunchScrollView DataSources

- (NSInteger)punchscrollView:(PagingView *)scrollView numberOfPagesInSection:(NSInteger)section{
    return [self.array count];
}


- (UIView*)punchScrollView:(PagingView*)scrollView viewForPageAtIndexPath:(NSIndexPath *)indexPath
{
	PagingPage *page = (PagingPage*)[scrollView dequeueRecycledPage];
	if (page == nil)
	{        
		page = [[[PagingPage alloc] initWithFrame:self.view.bounds] autorelease];
        page.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	
    page.imageName = [self.array objectAtIndex:indexPath.row];
	return page;
}

- (void)punchScrollView:(PagingView*)scrollView pageChanged:(NSIndexPath*)indexPath{
    NSLog(@"当前页面是  : %d",indexPath.row);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self.scrollView updateForOrientationChange];
    [self.scrollView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end

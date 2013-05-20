//
//  PagingView.h
//  testScrollview
//
//  Created by 苏 孝禹 on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScrollViewDataSource;
@protocol ScrollViewDelegate;


typedef enum {
    ScrollViewDirectionHorizontal = 0,
    ScrollViewDirectionVertical = 1,
} ScrollViewDirection;

@interface PagingView : UIScrollView <UIScrollViewDelegate>{
    id <ScrollViewDataSource> scrollviewDataSource;
	id <ScrollViewDelegate> scrollviewDelegate;
    
	NSMutableSet                    *recycledPages_;
    NSMutableSet                    *visiblePages_;
    NSMutableArray                  *pageController_;
    
	NSInteger                       currentPageIndex_;
	NSMutableArray                  *indexPaths_;
	CGFloat                         currentWidth_;
    CGFloat                         pagePadding_;
    CGSize                          pageSizeWithPadding_;
    ScrollViewDirection        direction_;
}
// Set the DataSource for the Scroll Suite
@property (nonatomic, assign) id <ScrollViewDataSource> scrollviewDataSource;  

// set the Delegate for the Scroll Suite
@property (nonatomic, assign) id <ScrollViewDelegate> scrollviewDelegate;

// Set the padding between pages. Default is 10pt
@property (nonatomic, assign) CGFloat             pagePadding;       

// Set a Vertical or Horizontal Direction of the scrolling
@property (nonatomic, assign) ScrollViewDirection direction;                              

//  Get the current visible Page
@property (nonatomic, readonly) UIView *currentPage;  

//  Get the first Page
@property (nonatomic, readonly) UIView *firstPage;    

//  Get the last Page
@property (nonatomic, readonly) UIView *lastPage;         

//  Get the current visible indexPath
@property (nonatomic, readonly) NSIndexPath *currentIndexPath;       

//  Get the last indexPath of the Scroll Suite
@property (nonatomic, readonly) NSIndexPath *lastIndexPath; 

//  Get all Page Controller if given
@property (nonatomic, readonly) NSArray *pageController;                                          

//屏幕旋转时 调用 
-(void)updateForOrientationChange;


/*
 * Init Method for PunchScrollView
 *
 */
- (id)init; 
- (id)initWithFrame:(CGRect)aFrame;

/*
 * This Method returns a UIView which is in the Queue
 */
- (UIView *)dequeueRecycledPage;


/*
 * This Method reloads the data in the scrollView
 */
- (void)reloadData;


/*
 * This Method returns an UIView for a given indexPath
 *
 */
- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath;

/*
 * Some Scrolling to page methods
 *
 */
- (void)scrollToIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated;
- (void)scrollToNextPage:(BOOL)animated;
- (void)scrollToPreviousPage:(BOOL)animated;


@end



/* 
 *  PunchScrollView Delegate Methods
 *
 */

@protocol ScrollViewDelegate <NSObject>

@optional

- (void)punchScrollView:(PagingView *)scrollView pageChanged:(NSIndexPath*)indexPath;

@end


/*
 * PunchScrollView DataSource Methods
 *
 */

@protocol ScrollViewDataSource <NSObject>

@required

- (NSInteger)punchscrollView:(PagingView *)scrollView numberOfPagesInSection:(NSInteger)section;

@optional

- (NSInteger)numberOfSectionsInPunchScrollView:(PagingView *)scrollView;        // Default is 1 if not implemented

- (UIView*)punchScrollView:(PagingView*)scrollView viewForPageAtIndexPath:(NSIndexPath *)indexPath;

- (UIViewController*)punchScrollView:(PagingView*)scrollView controllerForPageAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)numberOfLazyLoadingPages;

@end

//
//  PunchScrollView.m
//  
//
//  Created by tapwork. on 20.10.10. 
//
//  Copyright 2010 tapwork. mobile design & development. All rights reserved.
//  tapwork.de

#import "PagingView.h"

@interface PagingView ()
{
    BOOL orientationChangeInProcess_;
}

@property (nonatomic, readonly) CGSize pageSizeWithPadding;
@property (nonatomic, readonly) NSArray *storedPages;

- (UIView*)askDataSourceForPageAtIndex:(NSInteger)index;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (CGRect)frameForPage:(UIView*)page atIndex:(NSUInteger)index;
- (void)updateFrameForAvailablePages;
- (void)updateContentSize;
- (void)loadPages;
- (void)pageIndexChanged;
- (void)setIndexPaths;
- (NSUInteger)sectionCount;
- (NSUInteger)pagesCount;
- (NSIndexPath*)indexPathForIndex:(NSInteger)index;

@end

@implementation PagingView


@synthesize scrollviewDataSource = scrollviewDataSource_;
@synthesize scrollviewDelegate = scrollviewDelegate_;

@synthesize pagePadding = pagePadding_;
@synthesize direction = direction_;

@dynamic currentIndexPath;
@dynamic lastIndexPath;
@dynamic currentPage;
@dynamic firstPage;
@dynamic lastPage;
@dynamic pageController;

- (id)init
{
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if ((self = [super initWithFrame:aFrame]))
	{
        pageSizeWithPadding_ = CGSizeZero;
        
        self.pagePadding = 0;
        
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.delegate = self;  
 		self.pagingEnabled = YES;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.directionalLockEnabled = YES;
		
		indexPaths_     = [[NSMutableArray alloc] init];
		recycledPages_  = [[NSMutableSet alloc] init];
		visiblePages_   = [[NSMutableSet alloc] init];		
		
    }
    return self;
}



- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.scrollviewDataSource = nil;
	self.scrollviewDelegate = nil;
	[indexPaths_ release];
	indexPaths_ = nil;
	[recycledPages_ release];
	recycledPages_ = nil;
	[visiblePages_ release];
	visiblePages_ = nil;
    [pageController_ release];
    pageController_ = nil;
    
    [super dealloc];
}


//屏幕旋转时调用 
-(void)updateForOrientationChange{
    NSIndexPath *indexPath = [self indexPathForIndex:currentPageIndex_];
    [self scrollToIndexPath:indexPath animated:NO]; //让其移动到当前页 
    
    
    
}

#pragma mark -
#pragma mark PunchScrollView Public Methods

- (UIView *)dequeueRecycledPage
{
    UIView *page = [recycledPages_ anyObject];
    if (page)
    {
        [[page retain] autorelease];
        [recycledPages_ removeObject:page];
        [page removeFromSuperview];
    }
    return page;
}

//存储Pages
- (NSArray*)storedPages
{
    NSArray *storedPages = [NSArray arrayWithArray:[recycledPages_ allObjects]];
    
    return [storedPages arrayByAddingObjectsFromArray:[visiblePages_ allObjects]];
}

- (UIView*)pageForIndexPath:(NSIndexPath*)indexPath
{
    
    for (UIView *thePage in self.storedPages)
	{
		if ((NSNull*)thePage == [NSNull null]) break;
		NSIndexPath *storedIndexPath = [self indexPathForIndex:thePage.tag];
		
        if (storedIndexPath.row == indexPath.row &&
            storedIndexPath.section == indexPath.section)
		{
            return thePage;
        }
    }
	
	
    return nil;
}



- (void)scrollToIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
	NSInteger pageNum = 0;
    
    BOOL indexPathFound = NO;
	for (NSIndexPath *storedPath in indexPaths_)
	{
		if (storedPath.section == indexPath.section && storedPath.row == indexPath.row)
		{
			indexPathFound = YES;
            break;
		}
        
		pageNum++;
	}
	
    if (indexPathFound == NO)
    {
        // The indexPath is not avaiable. go out, but do not crash and burn
        return;
    }
    
    
    if (direction_ == ScrollViewDirectionHorizontal)
    {
        
        [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*pageNum,
                                           0)
                      animated:animated];
	}
    else if (direction_ == ScrollViewDirectionVertical)
    {
        [self setContentOffset:CGPointMake(0,
                                           self.pageSizeWithPadding.height*pageNum)
                      animated:animated];
    }
	if (animated == NO)
	{
		[self pageIndexChanged];
	}
}

//进入下一页 
- (void)scrollToNextPage:(BOOL)animated
{
	NSIndexPath *indexPath = [self indexPathForIndex:currentPageIndex_+1];
    
    if (indexPath != nil)
    {
        [self scrollToIndexPath:indexPath animated:animated];
        if (animated == NO)
        {
            [self pageIndexChanged];
        }
    }
}

//返回前一页 
- (void)scrollToPreviousPage:(BOOL)animated
{
	NSIndexPath *indexPath = [self indexPathForIndex:currentPageIndex_-1];
    
    if (indexPath != nil)
    {
        [self scrollToIndexPath:indexPath animated:animated];
        if (animated == NO)
        {
            [self pageIndexChanged];
        }	
    }
}

//获得当前页面 
- (NSIndexPath*)currentIndexPath
{
	if (currentPageIndex_ >= self.pagesCount)
    {
        return nil;
    }
    return [self indexPathForIndex:currentPageIndex_];
}

- (NSIndexPath*)lastIndexPath
{
	return [indexPaths_ lastObject];
}
//当前页 
- (UIView*)currentPage
{
    return [self pageForIndexPath:self.currentIndexPath];
}

//第一页 
- (UIView*)firstPage
{
    return [self pageForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}
//最后一页
- (UIView*)lastPage
{
    return [self pageForIndexPath:self.lastIndexPath];
}

- (NSArray*)pageController
{
    return pageController_;
}

- (void)reloadData
{
    [self setIndexPaths];
    
    pageSizeWithPadding_ = CGSizeZero;
    
    for (UIView *view in self.storedPages)
    {
        [view removeFromSuperview];
        view = nil;
    }
    
    [visiblePages_ removeAllObjects];
    [recycledPages_ removeAllObjects];
    
    [self updateContentSize];
    
    if (direction_ == ScrollViewDirectionHorizontal)
    {
        [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*currentPageIndex_, 0)
                      animated:NO];
    }
    else if (direction_ == ScrollViewDirectionVertical)
    {
        [self setContentOffset:CGPointMake(0, self.pageSizeWithPadding.height*currentPageIndex_)
                      animated:NO];
    }
    [self loadPages];
}



#pragma mark -
#pragma mark -
#pragma mark Tiling and page configuration
- (void)layoutSubviews
{
	[super layoutSubviews];
    
    orientationChangeInProcess_ = NO;
	if (currentWidth_ != self.frame.size.width)
	{        
        pageSizeWithPadding_ = CGSizeZero;
		orientationChangeInProcess_ = YES;
	}
	
	currentWidth_ = self.frame.size.width;
	
    [self updateContentSize];
    
	if (orientationChangeInProcess_ == YES)
	{
		if (direction_ == ScrollViewDirectionHorizontal)
        {
            [self setContentOffset:CGPointMake(self.pageSizeWithPadding.width*currentPageIndex_, 0)
                          animated:NO];
        }
        else if (direction_ == ScrollViewDirectionVertical)
        {
            [self setContentOffset:CGPointMake(0, self.pageSizeWithPadding.height*currentPageIndex_)
                          animated:NO];
        }
        
        [self updateFrameForAvailablePages];
    }
    
    orientationChangeInProcess_ = NO; 
}

- (void)loadPages 
{
    if ([self pagesCount]  == 0 ||
        (self.scrollviewDataSource == nil))
    {
        
        // do not render the pages if there is not at least one page
        
        return;
    }
    
    int lazyOfLoadingPages = 0;
    NSMutableArray *controllerViewsToDelete = [[NSMutableArray alloc] init];
    if ([self.scrollviewDataSource respondsToSelector:@selector(numberOfLazyLoadingPages)]) {
           lazyOfLoadingPages = [self.scrollviewDataSource numberOfLazyLoadingPages];
    }
    

    
    
    
    // Calculate which pages are visible
    CGRect visibleBounds = self.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = ceil(CGRectGetMaxX(visibleBounds) / self.pageSizeWithPadding.width);
    
    if (direction_ == ScrollViewDirectionVertical)
    {
        firstNeededPageIndex = floorf(CGRectGetMinY(visibleBounds) / CGRectGetHeight(visibleBounds));
        lastNeededPageIndex  = ceil(CGRectGetMaxY(visibleBounds) / self.pageSizeWithPadding.height);
    }
    
    firstNeededPageIndex = MAX(firstNeededPageIndex-lazyOfLoadingPages-1, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex+lazyOfLoadingPages, [self pagesCount] - 1);
    
    // Recycle no-longer-visible pages 
    for (UIView *page in visiblePages_)
    {
        int indexToDelete = page.tag;
        if (indexToDelete < firstNeededPageIndex ||
            indexToDelete > lastNeededPageIndex)
        {
            //
            // If we work in controller mode
            if (pageController_ != nil &&
                indexToDelete >= 0 &&
                indexToDelete < [pageController_ count])
            {
                UIViewController *vc = [pageController_ objectAtIndex:indexToDelete];
                [controllerViewsToDelete addObject:vc];
            }
            //
            // if we work in view mode
            else if (pageController_ == nil)
            {
                [recycledPages_ addObject:page];
            }
            
        }
    }
    
    [visiblePages_ minusSet:recycledPages_];
    
    //
    // Force Deletion
    for (UIViewController *vc in controllerViewsToDelete)
    {
        [visiblePages_ removeObject:vc.view];
        [vc.view removeFromSuperview];
        [vc viewDidUnload];
        vc.view = nil;
    }
    [controllerViewsToDelete release];
    
    
    //
    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) 
    {
        if (![self isDisplayingPageForIndex:index])
		{
			
			UIView *page = [self askDataSourceForPageAtIndex:index];            
            
			if (nil != page)
			{
				page.tag = index;
				[page layoutIfNeeded];
                page.frame = [self frameForPage:page atIndex:index]; 
				[self addSubview:page];
				[visiblePages_ addObject:page];
				
			}
			else
			{
				[visiblePages_ addObject:[NSNull null]];
			}
			
        }
    }    
}

- (UIView*)askDataSourceForPageAtIndex:(NSInteger)index
{
    UIView *page = nil;
    
    if ([self.scrollviewDataSource respondsToSelector:@selector(punchScrollView:controllerForPageAtIndexPath:)])
    {
        if (pageController_ == nil)
        {
            pageController_ = [[NSMutableArray alloc] init];
        }
        
        UIViewController *controller = [self.scrollviewDataSource
                                        punchScrollView:self
                                        controllerForPageAtIndexPath:[self indexPathForIndex:index]];
        if (![pageController_ containsObject:controller] &&
            controller != nil)
        {
            [pageController_ addObject:controller];
        }
        
        page = controller.view;
        
    }
    else if ([self.scrollviewDataSource respondsToSelector:@selector(punchScrollView:viewForPageAtIndexPath:)])
    {
        page = [self.scrollviewDataSource punchScrollView:self viewForPageAtIndexPath:[self indexPathForIndex:index]];
    }
    
    
    return page;
}


- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (UIView *page in visiblePages_)
    {
        if (page.tag == index)
        {
            return YES;
        }
    }
    return foundPage;
}

- (void)setPunchDataSource:(id <ScrollViewDataSource>)thePunchDataSource
{
	if (scrollviewDataSource != thePunchDataSource)
    {
        scrollviewDataSource = thePunchDataSource;
        if (scrollviewDataSource != nil)
        {
            [self reloadData];
        }
    }
}



#pragma mark -
#pragma mark ScrollView delegate methods


- (void)scrollViewDidScroll:(PagingView *)scrollView
{
    //
    // Check if the page really has changed
    //
    BOOL pageChanged = NO;
    if (direction_ == ScrollViewDirectionHorizontal)
    {
        if ( (int)(self.contentOffset.x) % MAX((int)(self.pageSizeWithPadding.width),1) == 0)
        {
            pageChanged = YES;
        }
	}
    else if (direction_ == ScrollViewDirectionVertical)
    {
        if ( (int)(self.contentOffset.y) % MAX((int)(self.pageSizeWithPadding.height),1) == 0)
        {
            pageChanged = YES;
        }
    }
    
    
    if (pageChanged == YES && 
        orientationChangeInProcess_ == NO)
    {
        [self pageIndexChanged];
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self loadPages];
}

- (void)scrollViewDidEndDecelerating:(PagingView *)scrollView 
{
    [self pageIndexChanged];
}

- (void)scrollViewDidEndScrollingAnimation:(PagingView *)scrollView
{
	[self pageIndexChanged];
}

- (void)pageIndexChanged
{
    NSInteger newPageIndex = NSNotFound;
    
    [self loadPages];
    
    if (direction_ == ScrollViewDirectionHorizontal)
    {
        CGFloat pageWidth = self.pageSizeWithPadding.width;
        newPageIndex = floor(self.contentOffset.x) / floor(pageWidth);
	}
    else if (direction_ == ScrollViewDirectionVertical)
    {
        CGFloat pageHeight = self.pageSizeWithPadding.height;
        newPageIndex = floor(self.contentOffset.y) / floor(pageHeight);
    }
    
    if (newPageIndex != currentPageIndex_)
    {
        currentPageIndex_ = newPageIndex;
        if ([self.scrollviewDelegate respondsToSelector:@selector(punchScrollView:pageChanged:)] &&
            self.pagesCount > 0)
        {
            [self.scrollviewDelegate punchScrollView:self
                                    pageChanged:[self indexPathForIndex:currentPageIndex_]];
        }
	}
}



#pragma mark -
#pragma mark Page Frame calculations

- (void)setPagePadding:(CGFloat)pagePadding
{
    if (pagePadding_ != pagePadding)
    {
        pagePadding_ = pagePadding;
        
        CGRect frame = self.frame;
        if (direction_ == ScrollViewDirectionHorizontal)
        {
            frame.origin.x -= self.pagePadding;
            frame.size.width += (2 * self.pagePadding);
        }
        else if (direction_ == ScrollViewDirectionVertical)
        {
            frame.origin.y -= self.pagePadding;
            frame.size.height += (2 * self.pagePadding);
        }
        
        [super setFrame:frame];
        
        [self reloadData];
    }
}



- (void)updateContentSize
{
    if (direction_ == ScrollViewDirectionHorizontal)
    {
        self.contentSize = CGSizeMake(self.pageSizeWithPadding.width * [self pagesCount],
                                      self.contentSize.height);
	}
    else if (direction_ == ScrollViewDirectionVertical)
    {
        self.contentSize = CGSizeMake(self.contentSize.width,
                                      self.pageSizeWithPadding.height* [self pagesCount]);
    }
}


- (void)updateFrameForAvailablePages
{
	for (UIView *page in self.storedPages)
	{
		if ((NSNull*)page != [NSNull null])
        {
            page.frame = [self frameForPage:page
                                    atIndex:page.tag];
        }
	}
}

- (CGRect)frameForPage:(UIView*)page atIndex:(NSUInteger)index
{
    
    CGRect pageFrame = CGRectMake(self.bounds.origin.x,
                                  self.bounds.origin.y,
                                  page.frame.size.width,
                                  page.frame.size.height);
    
    
    if (direction_ == ScrollViewDirectionHorizontal)
    {
        pageFrame.origin.x = (self.pageSizeWithPadding.width * index) + self.pagePadding;
        pageFrame.origin.y = page.frame.origin.y;
    }
    else if (direction_ == ScrollViewDirectionVertical)
    {
        pageFrame.origin.x = page.frame.origin.x;
        pageFrame.origin.y = (self.pageSizeWithPadding.height * index) + self.pagePadding;
    }
    
    
    return pageFrame;
}



- (void)setDirection:(ScrollViewDirection)direction
{
    if (direction_ != direction)
    {
        direction_ = direction;
        [self reloadData];
    }
}

- (CGSize)pageSizeWithPadding
{
    
    if (self.pagesCount == 0)
    {
        
        pageSizeWithPadding_ = CGSizeZero; 
        
        return pageSizeWithPadding_;
    }
    
    CGSize size = pageSizeWithPadding_;
    if (CGSizeEqualToSize(size,CGSizeZero))
    {
        UIView *page = [self.storedPages lastObject];
        if (page == nil)
        {
            page = [self askDataSourceForPageAtIndex:0];
        }
        if (page != nil)
        {
            size = page.bounds.size;
            
            if (direction_ == ScrollViewDirectionHorizontal)
            {
                size = CGSizeMake(size.width+(2*self.pagePadding),size.height);
            }
            else if (direction_ == ScrollViewDirectionVertical)
            {
                size = CGSizeMake(size.width,size.height+(2*self.pagePadding));
            }
            
            pageSizeWithPadding_ = size;
        }
    }
    
    
    return pageSizeWithPadding_;
}




#pragma mark -
#pragma mark Count & hold the data Source



- (NSUInteger)sectionCount
{
	if ([self.scrollviewDataSource respondsToSelector:@selector(numberOfSectionsInPunchScrollView:)])
    {
        return [self.scrollviewDataSource numberOfSectionsInPunchScrollView:self];
    }
    return 1;
}

- (NSUInteger)pagesCount {
    
	return [indexPaths_ count];
	
}


- (void)setIndexPaths
{
	[indexPaths_ removeAllObjects];
    
    for (int section = 0; section < [self sectionCount]; section++)
	{
		NSUInteger rowsInSection = 1;
		if ([self.scrollviewDataSource respondsToSelector:@selector(punchscrollView:numberOfPagesInSection:)])
		{
			rowsInSection = [self.scrollviewDataSource punchscrollView:self numberOfPagesInSection:section];
		}
		
		for (int row = 0; row < rowsInSection; row++)
		{
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
			[indexPaths_ addObject:indexPath];
		}
	}
}

- (NSIndexPath*)indexPathForIndex:(NSInteger)index
{
    if (index < self.pagesCount &&
        index >= 0)
    {
        return [indexPaths_ objectAtIndex:index];
    }
    
    return nil;
}
@end
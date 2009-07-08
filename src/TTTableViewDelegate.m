#import "Three20/TTTableViewDelegate.h"
#import "Three20/TTTableViewDataSource.h"
#import "Three20/TTTableViewController.h"
#import "Three20/TTTableItem.h"
#import "Three20/TTTableItemCell.h"
#import "Three20/TTTableHeaderView.h"
#import "Three20/TTTableView.h"
#import "Three20/TTStyledTextLabel.h"
#import "Three20/TTAppMap.h"
#import "Three20/TTDefaultStyleSheet.h"
#import "Three20/TTURLRequestQueue.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static const CGFloat kEmptyHeaderHeight = 1;
static const CGFloat kSectionHeaderHeight = 35;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewDelegate

@synthesize controller = _controller;

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)initWithController:(TTTableViewController*)controller {
  if (self = [super init]) {
    _controller = controller;
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDelegate

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (tableView.style == UITableViewStylePlain && TTSTYLEVAR(tableHeaderTintColor)) {
    if ([tableView.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)]) {
      NSString* title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
      if (title.length) {
        return [[[TTTableHeaderView alloc] initWithTitle:title] autorelease];
      }
    }
  }
  return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  id<TTTableViewDataSource> dataSource = (id<TTTableViewDataSource>)tableView.dataSource;

  id object = [dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
  if ([object isKindOfClass:[TTTableLinkedItem class]]) {
    TTTableLinkedItem* item = object;
    if (item.URL && [_controller shouldNavigateToURL:item.URL]) {
      TTLoadURL(item.URL);
    }

    if ([object isKindOfClass:[TTTableButton class]]) {
      [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if ([object isKindOfClass:[TTTableMoreButton class]]) {
      TTTableMoreButton* moreLink = (TTTableMoreButton*)object;
      moreLink.isLoading = YES;
      TTTableMoreButtonCell* cell
        = (TTTableMoreButtonCell*)[tableView cellForRowAtIndexPath:indexPath];
      cell.animating = YES;
      [tableView deselectRowAtIndexPath:indexPath animated:YES];
      
      [dataSource load:TTURLRequestCachePolicyDefault nextPage:YES];
    }
  }

  [_controller didSelectObject:object atIndexPath:indexPath];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIScrollViewDelegate

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
  [TTURLRequestQueue mainQueue].suspended = YES;
  return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
  [TTURLRequestQueue mainQueue].suspended = NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [TTURLRequestQueue mainQueue].suspended = YES;

  [_controller didBeginDragging];
  
  if ([scrollView isKindOfClass:[TTTableView class]]) {
    TTTableView* tableView = (TTTableView*)scrollView;
    [tableView hideMenu:YES];
    
    tableView.highlightedLabel.highlightedNode = nil;
    tableView.highlightedLabel = nil;
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
  if (!decelerate) {
    [TTURLRequestQueue mainQueue].suspended = NO;
  }

  [_controller didEndDragging];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  [TTURLRequestQueue mainQueue].suspended = NO;
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewVarHeightDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
  id<TTTableViewDataSource> dataSource = (id<TTTableViewDataSource>)tableView.dataSource;

  id object = [dataSource tableView:tableView objectForRowAtIndexPath:indexPath];
  Class cls = [dataSource tableView:tableView cellClassForObject:object];
  return [cls tableView:tableView rowHeightForItem:object];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewPlainDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDelegate

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSString* title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
  if (!title.length)
    return nil;

  return [[[TTTableHeaderView alloc] initWithTitle:title] autorelease];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTTableViewPlainVarHeightDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDelegate

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSString* title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
  if (!title.length)
    return nil;

  return [[[TTTableHeaderView alloc] initWithTitle:title] autorelease];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface TTTableViewGroupedVarHeightDelegate : TTTableViewVarHeightDelegate
@end

@implementation TTTableViewGroupedVarHeightDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
// UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
  NSString* title = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
  if (!title.length) {
    return kEmptyHeaderHeight;
  } else {
    return kSectionHeaderHeight;
  }
}

@end

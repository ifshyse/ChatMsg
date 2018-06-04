//
//  FacesView.h
//  student
//
//  Created by Stephen on 2018/5/29.
//  Copyright © 2018年 YiMi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SCROLL_PAGE_WIDTH   (600)
#define SCROLL_PAGE_HEIGHT  (300)
#define FACE_WIDTH     (60.0)

@protocol FacesViewDelegate <NSObject>

- (void)pageNumber:(int)page location:(int)location;
- (void)backToRoot;
@end

@interface FacesView : UIScrollView

@property (nonatomic, strong) NSArray* faces;
@property (nonatomic, weak) id<FacesViewDelegate> protocol;

@end

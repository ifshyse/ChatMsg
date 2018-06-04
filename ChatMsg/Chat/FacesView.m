//
//  FacesView.m
//  student
//
//  Created by Stephen on 2018/5/29.
//  Copyright © 2018年 YiMi. All rights reserved.
//

#import "FacesView.h"

@protocol FaceViewDelegate <NSObject>

- (void)pageNumber:(int)page location:(int)location;

@end

@interface FaceView : UIView

@property (nonatomic, strong) NSArray* faces;
@property (nonatomic, weak) id<FaceViewDelegate> delegate;

@end

@implementation FaceView

- (instancetype)initWithFrame:(CGRect)frame faces:(NSArray*)faces
{
    if (self = [super initWithFrame:frame]) {
        _faces = faces;
        for (int i = 0; i < faces.count; i++) {
            NSString* face = [faces objectAtIndex:i];
            UIImage* image = [UIImage imageNamed:face];
            
            UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake((i%(int)(SCROLL_PAGE_WIDTH/FACE_WIDTH))*FACE_WIDTH, (i/(int)(SCROLL_PAGE_WIDTH/FACE_WIDTH))*FACE_WIDTH, FACE_WIDTH, FACE_WIDTH)];
            imgView.image = image;
            imgView.tag = i;
            imgView.userInteractionEnabled = YES;
            UITapGestureRecognizer* ges = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(faceClick:)];
            [imgView addGestureRecognizer:ges];
            [self addSubview:imgView];
        }
    }
    return self;
}

- (void)faceClick:(UITapGestureRecognizer*)gesture {
    int tag = (int)gesture.view.tag;
    NSLog(@"face tag: %d" , tag);
    if (self.delegate) {
        [self.delegate pageNumber:(int)self.tag location:tag];
    }
}
@end

@interface FacesView()
<
FaceViewDelegate
>

@end

@implementation FacesView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _faces = [[NSArray alloc] init];
        self.backgroundColor = [UIColor whiteColor];
        UIButton* backBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 25, -25, 50, 50)];
        [backBtn setTitle:@"back" forState:UIControlStateNormal];
        [backBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:backBtn];
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setFaces:(NSArray *)faces {
    _faces = faces;
    int per_page_count = (SCROLL_PAGE_WIDTH/FACE_WIDTH)*(SCROLL_PAGE_HEIGHT/FACE_WIDTH);
    int pageCount = (int)(_faces.count / per_page_count)+1;
    for(int i = 0; i< pageCount;i++) {
        int count = per_page_count;
        if (i == pageCount - 1) {
            if(i==0) {
                count = (int)_faces.count;
            }else {
                count = (int)_faces.count - i*per_page_count;
            }
        }
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                               NSMakeRange(per_page_count*i,count)];
        NSArray *resultArray = [_faces objectsAtIndexes:indexes];
        FaceView* view = [[FaceView alloc] initWithFrame:CGRectMake(i*SCROLL_PAGE_WIDTH, 0, SCROLL_PAGE_WIDTH, SCROLL_PAGE_HEIGHT) faces:resultArray];
        view.tag = i;
        view.delegate = self;
        [self addSubview:view];
    }
    self.contentSize = CGSizeMake(pageCount*SCROLL_PAGE_WIDTH,SCROLL_PAGE_HEIGHT);
}

- (void)back:(UIButton*)sender
{
    if (self.protocol) {
        [self.protocol backToRoot];
    }
}

- (void)pageNumber:(int)page location:(int)location
{
    if (self.protocol) {
        [self.protocol pageNumber:page location:location];
    }
}

@end

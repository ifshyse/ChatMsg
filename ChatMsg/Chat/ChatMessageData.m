//
//  ChatMessageData.h
//  whiteBoard
//
//  Created by stephen on 5/28/18.
//  Copyright (c) 2018 JR. All rights reserved.
//

#import "ChatMessageData.h"
//#import "CommonDefine.h"

@implementation ChatMessageData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _messages = [[NSMutableArray alloc] init];
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        self.outgoingBubbleImageData = [JSQMessagesBubbleImageFactory outgoingMessagesBubbleImageWithColor:[UIColor colorWithHexString:@"DDF0ED"]];
        
        self.incomingBubbleImageData = [JSQMessagesBubbleImageFactory incomingMessagesBubbleImageWithColor:[UIColor colorWithHexString:@"EEEEFF"]];
    }
    
    return self;
}


- (void)addPhotoMediaMessage
{
    /*
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"goldengate"]];
    JSQMediaMessage *photoMessage = [JSQMediaMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                             displayName:kJSQDemoAvatarDisplayNameSquires
                                                                   media:photoItem];
    [self.messages addObject:photoMessage];*/
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    /*
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
    
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    
    JSQMediaMessage *locationMessage = [JSQMediaMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                                displayName:kJSQDemoAvatarDisplayNameSquires
                                                                      media:locationItem];
    [self.messages addObject:locationMessage];*/
}

@end

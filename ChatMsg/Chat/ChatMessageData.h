//
//  ChatMessageData.h
//  whiteBoard
//
//  Created by stephen on 5/28/18.
//  Copyright (c) 2018 JR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"


@interface ChatMessageData : NSObject

// JSQMessage array
@property (strong, nonatomic) NSMutableArray *messages;

// [@"avatr id", JSQMessagesAvatarImage]
@property (strong, nonatomic) NSDictionary *avatars;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) NSDictionary *users;

- (void)addPhotoMediaMessage;

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;

@end

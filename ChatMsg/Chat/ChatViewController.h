//
//  ChatViewController.h
//  whiteBoard
//
//  Created by stephen on 5/28/18.
//  Copyright (c) 2018 JR. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import "YiMiCommandConvert.h"
#import "GPLSocketSaveLocal.h"
#import "GPLSocketSendLocal.h"
#import "JSQTextMessage.h"

#define QStringLiteral(str) ([NSString stringWithFormat:@"[%@]",str])
#define FacesList ([[NSMutableArray alloc] initWithObjects:QStringLiteral(@"微笑"),QStringLiteral(@"撇嘴"),QStringLiteral(@"色"),QStringLiteral(@"发呆"),               QStringLiteral(@"得意"),QStringLiteral(@"流泪"),QStringLiteral(@"害羞"),QStringLiteral(@"闭嘴"),               QStringLiteral(@"睡"),QStringLiteral(@"大哭"),QStringLiteral(@"尴尬"),QStringLiteral(@"发怒"),               QStringLiteral(@"调皮"),QStringLiteral(@"呲牙"),QStringLiteral(@"惊讶"),QStringLiteral(@"难过"),               QStringLiteral(@"囧"),QStringLiteral(@"抓狂"),QStringLiteral(@"汗"),QStringLiteral(@"偷笑"),               QStringLiteral(@"可爱"),QStringLiteral(@"白眼"),QStringLiteral(@"傲慢"),QStringLiteral(@"困"),               QStringLiteral(@"高兴"),QStringLiteral(@"悠闲"),QStringLiteral(@"奋斗"),QStringLiteral(@"疑问"),               QStringLiteral(@"嘘"),QStringLiteral(@"敲打"),QStringLiteral(@"再见"),QStringLiteral(@"抠鼻"),               QStringLiteral(@"鼓掌"),QStringLiteral(@"扶额"),QStringLiteral(@"委屈"),QStringLiteral(@"鄙视"),               QStringLiteral(@"噢耶"),QStringLiteral(@"放学你别走"),QStringLiteral(@"可怜"),QStringLiteral(@"西瓜"),               QStringLiteral(@"啤酒"), QStringLiteral(@"咖啡"),QStringLiteral(@"猪头"),QStringLiteral(@"玫瑰"),               QStringLiteral(@"凋谢"),QStringLiteral(@"嘴唇"),QStringLiteral(@"爱心"),QStringLiteral(@"蛋糕"),               QStringLiteral(@"太阳"), QStringLiteral(@"抱抱"),QStringLiteral(@"强"),QStringLiteral(@"握手"),               QStringLiteral(@"胜利"), QStringLiteral(@"抱拳"),QStringLiteral(@"拳头"),QStringLiteral(@"OK"), nil])

@protocol ChatViewControllerDelegate <NSObject>
@optional
- (void)facesBtnTouched;
- (void)finishSendMessage;

@end

@interface ChatViewController : JSQMessagesViewController

@property (copy) dispatch_block_t           completion;
@property (copy) void(^backBlock)(void);

@property(assign, readwrite) BOOL           removeAvatars;
@property(assign, readwrite) BOOL           canNotSent;

@property (nonatomic, retain) NSString      *buddyId;
@property (nonatomic, retain) NSString      *placeholder;
@property (nonatomic, retain) NSString      *lessonId;

@property (nonatomic, weak) YiMiCommandConvert* commandConvertor;
@property (nonatomic, weak) GPLSocketSaveLocal* gplSaveLocal;
@property (nonatomic, weak) GPLSocketSendLocal* gplSendLocal;

@property (nonatomic, weak) id<ChatViewControllerDelegate> delegate;

- (void)sendTextMessage:(NSString*)text;
+ (NSString*)encrypt:(NSString*)text;
- (void)newChatMsgReceived:(JSQTextMessage *)message;
- (NSString*)textFromTextView;
- (void)setTextView:(NSString*)string;

@end

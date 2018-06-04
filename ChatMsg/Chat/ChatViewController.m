//
//  ChatViewController.h
//  whiteBoard
//
//  Created by stephen on 5/28/18.
//  Copyright (c) 2018 JR. All rights reserved.
//

#import "ChatViewController.h"
#import "JSQMessages.h"
//#import "XmppManager.h"
#import "GTMBase64.h"

#import "ChatMessageData.h"
//#import "CommonDefine.h"
//#import "ApplicationManager.h"
//#import "ConfigureObject.h"
#import "KxMenu.h"
#import "SocketManager.h"
#import "JSONKit.h"
#import "protocol.h"

static char key[] = "JRbdAG8P";

@interface ChatViewController ()
<
UIActionSheetDelegate
>

//@property (nonatomic, retain) XmppManager *xmppManager;

//@property (strong, nonatomic) NSMutableArray *messages;
//@property (strong, nonatomic) NSMutableDictionary *avatars;


@property (strong, nonatomic) ChatMessageData *chatMessageData;

- (IBAction)onDoneTouched:(id)sender;
- (IBAction)onMoreTouched:(UIControl *)sender;
- (IBAction)onExitTouched:(id)sender;

@end

@implementation ChatViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _removeAvatars = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.view.layer.borderWidth = 0.5;
    
    self.navigationController.navigationBarHidden = NO;
    
    self.keyboardController = nil;
    
    _chatMessageData = [[ChatMessageData alloc] init];
    
    NSParameterAssert([self.buddyId length] > 0);
    
    if (![self.buddyId containsString:@"@"]) {
        //self.buddyId = [NSString stringWithFormat:@"%@@%@", self.buddyId, [ApplicationManager sharedManager].configureObject.chat_xmpp];
    }
//    _xmppManager.partnerJID = self.buddyId;
//
//    [_xmppManager setReadChatMessageFromStorage:self.buddyId];
//
//
    
    [_chatMessageData.messages  addObjectsFromArray:_gplSaveLocal.msgLocal];
    
    // remove avatar
    if (self.removeAvatars) {
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    }
    
    //UIBarButtonItem* leftBarItem = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStylePlain target:self action:@selector(onMoreTouched:)];
    //self.inputToolbar.contentView.leftBarButtonItem = leftBarItem;
    
    //self.senderId = _xmppManager.myJID;
    
    self.inputToolbar.contentView.textView.placeHolder = self.placeholder;

    if (self.canNotSent) {
        self.inputToolbar.hidden = YES;
        self.inputToolbar.frame = CGRectZero;
//        [self.inputToolbar removeFromSuperview];
    }
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [button addTarget:self action:@selector(onExitTouched:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"back" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0] forState:UIControlStateNormal];
    [self.view addSubview:button];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
    self.collectionView.collectionViewLayout.springinessEnabled = NO;
    
    
    //[[ApplicationManager sharedManager].xmppManager4Chat registerDelegate:self];

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    //[[ApplicationManager sharedManager].xmppManager4Chat unregisterDelegateForce:self];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    _chatMessageData = nil;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    JSQTextMessage *message = [[JSQTextMessage alloc] initWithSenderId:senderId
                                                     senderDisplayName:senderDisplayName
                                                                  date:date
                                                                  text:text];
    
    [self.chatMessageData.messages addObject:message];
    [self finishSendingMessage];
    
    [self sendTextMessage:text];
    [self.delegate finishSendMessage];
}

#pragma mark - public
- (void)sendTextMessage:(NSString*)text
{
    //[[ApplicationManager sharedManager].xmppManager4Chat sendTextMessage:text];
//    NSDictionary *contentDic = @{@"domain":@"message",@"command":@"send",@"content":@{@"type":@"text",@"id":self.buddyId, @"message":[ChatViewController encrypt:text]}};
//    NSData* data = [contentDic JSONData];
    
    //const char* t = [data bytes];
    const char* t = (char*)[text UTF8String];
    int length = (int)strlen(t);
    int len =(int)strlen(t) + MSG_HEADER_SIZE + sizeof(struct msg_chatmsg_st);
    if (len > MSG_MAX_SIZE)
        return ;
    char *buff = (char*)malloc(len);
    memset(buff,0,len);
    
    msg_header_t pHeader = (msg_header_t)buff;
    msg_chatmsg_t pChatMsg = (msg_chatmsg_t)(buff + MSG_HEADER_SIZE);
    
    pHeader->len = len;
    pHeader->cmd = CMD_CHAT;
    pHeader->subcmd = CHATCMD_CHANNEL_CHAT;
    
    pChatMsg->uid = 0;
    pChatMsg->channel_id = [self.lessonId intValue];
    pChatMsg->msg_id = (int)rand();
    pChatMsg->content_len = strlen(t);
    memcpy(pChatMsg->content,t, length);
    NSData *data2 = [NSData dataWithBytes:buff length:len];
    
    [SOCKET_MANAGER sendData:data2 tag:self.gplSendLocal.tag];
    //[self.commandConvertor sendCommand:CommandConvertTypeMessageText content:contentDic tag:self.gplSendLocal.tag];
    NSLog(@"****connect---IM----********发送消息111111111111");
    JSQTextMessage* message = [JSQTextMessage messageWithSenderId:self.buddyId displayName:self.buddyId text:text/*[ChatViewController encrypt:text]*/];
    [self.gplSaveLocal saveMsgWithContext:message];
}

+ (NSString*)encrypt:(NSString*)text
{
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[data bytes];
    int keyLen = (int)strlen(key);
    for (int i = 0; i < sizeof(bytes); i++) {
        bytes[i] = bytes[i] ^ key[ i % keyLen ];
    }
    NSData *newData = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];
    return [GTMBase64 stringByEncodingData:newData];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
//    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
//                                                       delegate:self
//                                              cancelButtonTitle:@"Cancel"
//                                         destructiveButtonTitle:nil
//                                              otherButtonTitles:@"Send photo", @"Send location", nil];
//
//    [sheet showFromToolbar:self.inputToolbar];
    [self.delegate facesBtnTouched];
}

- (NSString*)textFromTextView
{
    return self.inputToolbar.contentView.textView.text;
}

- (void)setTextView:(NSString*)string
{
    self.inputToolbar.contentView.textView.text = string;
    self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            [self.chatMessageData addPhotoMediaMessage];
            break;
            
        case 1:
        {
            __weak UICollectionView *weakView = self.collectionView;
            
            [self.chatMessageData addLocationMediaMessageCompletion:^{
                [weakView reloadData];
            }];
        }
            break;
    }
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    [self finishSendingMessage];
}



#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.chatMessageData.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.chatMessageData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.chatMessageData.outgoingBubbleImageData;
    }
    
    return self.chatMessageData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [self.chatMessageData.messages objectAtIndex:indexPath.item];
    
    return [self.chatMessageData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.chatMessageData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.chatMessageData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.chatMessageData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.chatMessageData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.chatMessageData.messages objectAtIndex:indexPath.item];
    
    if ([msg isKindOfClass:[JSQTextMessage class]]) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor whiteColor];
        }
        else {
            cell.textView.textColor = [UIColor blackColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    __block NSString* str = msg.text;
    
    NSMutableArray* ranges = [[NSMutableArray alloc] init];
    
    [FacesList enumerateObjectsUsingBlock:^(NSString* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([FacesList containsObject:obj]) {
            NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]" options:0 error:nil];
            NSArray *results = [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
            for (int l = 0; l < results.count; l++) {
                NSTextCheckingResult* face = [results objectAtIndex:l];
                if(![ranges containsObject:NSStringFromRange(face.range)]) {
                    [ranges addObject:NSStringFromRange(face.range)];
                }
            }
        }
    }];
    
    if (ranges.count > 0) {
        [ranges sortUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            NSRange r1 = NSRangeFromString(obj1);
            NSRange r2 = NSRangeFromString(obj2);
            return r1.location > r2.location;
        }];
        NSMutableAttributedString* newStr = [[NSMutableAttributedString alloc] initWithString:str];
        for(int i = (int)ranges.count - 1;i >= 0;i--) {
            NSString* rangeStr = [ranges objectAtIndex:i];
            NSRange range = NSRangeFromString(rangeStr);
            NSString* s = [str substringWithRange:range];
            NSUInteger index = [FacesList indexOfObject:s];
            NSString* image = [NSString stringWithFormat:@"Expression_%lu",index+1];
            NSTextAttachment *attach = [[NSTextAttachment alloc] init];
            attach.image = [UIImage imageNamed:image];
            attach.bounds = CGRectMake(0, 0, 21, 21);
            NSAttributedString *attachString = [NSAttributedString attributedStringWithAttachment:attach];
            [newStr replaceCharactersInRange:range withAttributedString:attachString];
        }
        cell.textView.attributedText = newStr;
    }
    
    return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.chatMessageData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.chatMessageData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
#ifdef DEBUG
    NSLog(@"Load earlier messages!");
#endif
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
#ifdef DEBUG
    NSLog(@"Tapped avatar!");
#endif
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef DEBUG
    NSLog(@"Tapped message bubble!");
#endif
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
#ifdef DEBUG
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
#endif
}

- (JSQMessage *)dictToJSQMessage:(NSDictionary *)dict
{
    JSQMessage *newMessage;
    //BOOL isOutgoing     = [dict[@"isOutgoing"] boolValue];
    NSDate *msgDate     = dict[@"timestamp"];
    NSString *body      = dict[@"body"];
    NSString *from      = dict[@"chatwith"];
    NSString *displayName      = @"";
    //NSData *avatarData  = dict[@"chatWithAvatar"];

    if (body) {
        newMessage = [[JSQTextMessage alloc] initWithSenderId:from
                                            senderDisplayName:displayName
                                                         date:msgDate
                                                         text:body];
    }
    return newMessage;
}

#pragma mark - XMPPMessageDelegate
- (void)newChatMessageReceived:(NSDictionary *)messageContent
{
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    JSQMessage *newMessage = [self dictToJSQMessage:messageContent];
    if (newMessage) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            /**
             *  Upon receiving a message, you should:
             *
             *  1. Play sound (optional)
             *  2. Add new id<JSQMessageData> object to your data source
             *  3. Call `finishReceivingMessage`
             */
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            [self.chatMessageData.messages addObject:newMessage];
            [self finishReceivingMessage];
        });
    }
}

- (void)newChatMsgReceived:(JSQTextMessage *)message
{
    /**
     *  Show the typing indicator to be shown
     */
    self.showTypingIndicator = !self.showTypingIndicator;
    
    /**
     *  Scroll to actually view the indicator
     */
    [self scrollToBottomAnimated:YES];
    
    if (message) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            /**
             *  Upon receiving a message, you should:
             *
             *  1. Play sound (optional)
             *  2. Add new id<JSQMessageData> object to your data source
             *  3. Call `finishReceivingMessage`
             */
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            [self.chatMessageData.messages addObject:message];
            [self finishReceivingMessage];
        });
    }
}

- (IBAction)onDoneTouched:(id)sender {
    //[[ApplicationManager sharedManager].xmppManager4Chat setReadChatMessageFromStorage:self.buddyId];
    [self.gplSaveLocal saveMsg];
    if (self.completion) {
        self.completion();
    }
}

- (IBAction)onMoreTouched:(UIControl *)sender {
    NSArray *childNameArray = @[@"清除记录"];
    NSMutableArray *menuItems = [[NSMutableArray alloc] init];
    for (NSString *name in childNameArray) {
        KxMenuItem * menuItem = [KxMenuItem menuItem:name
                                               image:nil
                                              target:self action:@selector(onClearMenuTouched:)];
        [menuItems addObject:menuItem];
    }
    [KxMenu setTintColor:[UIColor whiteColor]];
    CGRect rect = sender.frame;
    rect.origin.x = rect.origin.x + rect.size.height/2;
    [KxMenu showMenuInView:self.view
                  fromRect:rect
                 menuItems:menuItems];
}

- (void)onClearMenuTouched:(KxMenuItem*)sender
{
    //[[ApplicationManager sharedManager].xmppManager4Chat removeChatMessageFromStorage:self.buddyId];
    [self.gplSaveLocal removeMsg];
    [_chatMessageData.messages  removeAllObjects];
    [self.collectionView reloadData];
}

- (IBAction)onExitTouched:(id)sender
{
    [self.gplSaveLocal saveMsg];
    if (self.backBlock) {
        self.backBlock();
    }
}

@end

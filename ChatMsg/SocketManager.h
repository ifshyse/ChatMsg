//
//  SocketManager.h
//  student
//
//  Created by Stephen on 2018/5/30.
//  Copyright © 2018年 YiMi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChannelInfoHeader.h"
#import "GPLSocketSendLocal.h"

#define SOCKET_MANAGER [SocketManager sharedInstance]

@interface SocketManager : NSObject
+ (SocketManager *)sharedInstance;

@property (nonatomic, copy) SocketSendCallBack socketCallBack;
@property (assign, nonatomic,readonly) BOOL isConnected;
@property (nonatomic ,weak) GPLSocketSendLocal *gplSendLocal;
/**
 链接socket
 
 @param host ip 地址
 @param port 端口
 */
//- (void)startConnectWithHost:(NSString*)host onPort:(uint16_t)port;
- (void)startConnectWithHost:(NSString*)host onPort:(uint16_t)port callBack:(SocketSendCallBack)callBack;
/**
 发送数据
 
 @param data 数据原型
 @param tag  标签
 */
- (void)sendData:(NSData*)data tag:(long)tag;


/**
 断开连接
 */
- (void)disconnect;

@end

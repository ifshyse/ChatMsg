//
//  SocketManager.m
//  student
//
//  Created by Stephen on 2018/5/30.
//  Copyright © 2018年 YiMi. All rights reserved.
//

#import "SocketManager.h"

#import "XYDNSManager.h"
#import "protocol.h"
#import "SocketClient.h"

#define SocketSenderTagNone (-100)

#define SOCKET_TIME_OUT 30

@interface SocketManager()
<SocketClientDelegate>

@property (strong, nonatomic) SocketClient  *socket;
@property (nonatomic, strong) NSThread *thread;
@property (nonatomic, strong) NSTimer* timer;
@property(nonatomic,strong) NSMutableData* responseData;

@property (assign, nonatomic) long readTag;

@end
@implementation SocketManager

static SocketManager *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}
- (void)dealloc {
    [self disconnect];
    _socket = nil;
    NSLog(@"SocketManager dealloc");
}

- (instancetype)init {
    if (self = [super init]) {
        //        NSString *ip = @"121.43.114.158";
        //        uint16_t port = 5122;
        //self.socket = [[AsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.socket = [[SocketClient alloc] init];
        self.socket.delegate = self;
        
        _readTag = 0;
        self.responseData = [[NSMutableData alloc] init];
    }
    return self;
}

-(BOOL)isConnected {
    return self.socket.isConnected;
}

- (void)threadStart{
    @autoreleasepool {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(heartBeat) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)heartBeat{
    DDLogInfo(@"sendHeartBeatIM = %@",[NSDate date]);
    //发送命令方法
    struct msg_header_st msghb;
    msghb.cmd = CMD_CHAT;
    msghb.subcmd = CHATCMD_HEART_BEAT;
    msghb.len = MSG_HEADER_SIZE;
    NSData *data = [NSData dataWithBytes:(char*)&msghb length:MSG_HEADER_SIZE];
    [SOCKET_MANAGER sendData:data tag:self.gplSendLocal.tag];
}

- (NSThread*)thread{
    if (!_thread) {
        _thread = [[NSThread alloc]initWithTarget:self selector:@selector(threadStart) object:nil];
    }
    return _thread;
}


-(void)disconnect {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    [_thread cancel];
    _thread = nil;
    [_socket disconnect];
}

/**
 链接socket
 
 @param host ip 地址
 @param port 端口
 */
- (void)startConnectWithHost:(NSString*)host onPort:(uint16_t)port callBack:(SocketSendCallBack)callBack {
    if (callBack) {
        self.socketCallBack = [callBack copy];
    }
    
    NSString* ipAddress = [host toIp];
    NSError *error = nil;
    BOOL result = [self.socket connectToHost:ipAddress onPort:port error:&error];
    if(!result) {
        NSLog(@"链接socket失败");
        if (self.socketCallBack) {
            self.socketCallBack(SocketSenderEventType_ErrorOnConnect,error,0, SocketSenderTagNone);
        }
    }else {
        [self.thread start];
    }
}

/**
 发送数据
 
 @param data 数据原型
 @param tag  标签
 */
- (void)sendData:(NSData*)data tag:(long)tag {
    @synchronized (self) {
        //[self.socket writeData:data withTimeout:SOCKET_TIME_OUT tag:tag];
        [self.socket sendData:data];
    }
}

/**
 断开连接
 */
- (void)socketDidDisconnect:(SocketClient *)sock withError:(NSError *)err {
    if (self.socketCallBack) {
        self.socketCallBack(SocketSenderEventType_Disconnect,err,0,SocketSenderTagNone);
    }
}

/**
 socket建立连接成功
 */
- (void)socket:(SocketClient *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    //[self.socket readDataWithTimeout:-1 tag:0];
    
    if (self.socketCallBack) {
    self.socketCallBack(SocketSenderEventType_Connect,nil,0,SocketSenderTagNone);
    }
    
    //[self.socket readDataToData:[AsyncSocket LFData] withTimeout:SOCKET_TIME_OUT tag:self.readTag];
}

/**
 接收消息回调
 */
- (void)socket:(SocketClient *)sock didReadData:(NSData *)data uid:(int)fromUID withTag:(long)tag {
    
    if (self.socketCallBack) {
        //[self.socket readDataWithTimeout:SOCKET_TIME_OUT tag:tag];
        self.socketCallBack(SocketSenderEventType_DataReceived,data,0,tag);
    }
//    [self.responseData appendData:data];
//    msg_header_t pch = (msg_header_t)[self.responseData bytes];
//    while (self.responseData.length >= MSG_HEADER_SIZE && self.responseData.length >= pch->len)
//    {
//        if (pch->cmd == CMD_CHAT && pch->subcmd == CHATCMD_CHANNEL_CHAT)
//        {
//            msg_chatmsg_t chatmsg = (msg_chatmsg_t)(pch + 1);
//            NSData *data = [NSData dataWithBytes:chatmsg->content length:chatmsg->content_len];
//            if (self.socketCallBack) {
//                self.responseData = [NSMutableData data];
//                [self.socket readDataWithTimeout:SOCKET_TIME_OUT tag:tag]; self.socketCallBack(SocketSenderEventType_DataReceived,data,tag);
//                break;
//            }
//        }
//        else if (pch->cmd == CMD_CHAT && pch->subcmd == CHATCMD_ERRCODE)
//        {
//            msg_errcode_ex_t errmsg = (msg_errcode_ex_t)(pch);
//            if (errmsg->code == ECLIENT_AUTHOK)
//            {
//                [self.socket readDataWithTimeout:SOCKET_TIME_OUT tag:tag];
//                break;
//            }
//        }
//        NSData* d = [self.responseData subdataWithRange:NSMakeRange(0, pch->len)];
//        pch = (msg_header_t)[d bytes];
//    }
    //NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"接收消息回调 = %@",aString);
    
    self.readTag++;
    //[self.socket readDataToData:[AsyncSocket LFData] withTimeout:SOCKET_TIME_OUT tag:self.readTag];
}

- (void)socket:(SocketClient *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    //[self.socket readDataToLength:partialLength withTimeout:0 tag:tag];
}
/**
 发送消息回调
 */
- (void)socket:(SocketClient *)sock didWriteDataWithTag:(long)tag {
//    if ([self.responseData isEqualToData:[NSData new]]) {
//        [self.socket readDataWithTimeout:20 buffer:[NSMutableData new] bufferOffset:0 tag:tag];
//    }
    // 需要自己调用读取方法，socket才会调用代理方法读取数据
    //[self.socket readDataWithTimeout:-1 tag:tag];
    if (self.socketCallBack) {
        self.socketCallBack(SocketSenderEventType_DataSended,nil,0,tag);
    }
}

- (NSTimeInterval)socket:(SocketClient *)sock
shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    return SOCKET_TIME_OUT;
}
- (NSTimeInterval)socket:(SocketClient *)sock
shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    return SOCKET_TIME_OUT;
}


@end

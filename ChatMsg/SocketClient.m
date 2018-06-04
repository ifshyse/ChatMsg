//
//  SocketClient.m
//  student
//
//  Created by Stephen on 2018/6/1.
//  Copyright © 2018年 YiMi. All rights reserved.
//

#import "SocketClient.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <netinet/tcp.h>
#include <netdb.h>
#include <sys/ioctl.h>
#import "protocol.h"
#include <mach/thread_act.h>
#include <pthread.h>
#include <unistd.h>

//@interface SocketOperation : NSBlockOperation
//
//@end
//
//@interface SocketOperation()
//
//
//
//@end
//
//@implementation SocketOperation
//@synthesize executing = _executing;
//@synthesize finished  = _finished;
//- (id)init {
//    self = [super init];
//    if (self) {
//        _executing = NO;
//        _finished  = NO;
//    }
//    return self;
//}
//- (BOOL)isConcurrent {
//    return YES;
//}
//- (BOOL)isExecuting {
//    return _executing;
//}
//- (BOOL)isFinished {
//    return _finished;
//}
//
//- (void)start {
//    if (self.isCancelled) {
//        [self willChangeValueForKey:@"isFinished"];
//        _finished = YES;
//        [self didChangeValueForKey:@"isFinished"];
//    }
//    [self willChangeValueForKey:@"isExecuting"];
//    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
//    _executing = YES;
//    [self didChangeValueForKey:@"isExecuting"];
//}
//
//- (void)main {
//    @try {
//        NSLog(@"Start executing %@, mainThread: %@, currentThread: %@", NSStringFromSelector(_cmd), [NSThread mainThread], [NSThread currentThread]);
//        sleep(3);
//        [self willChangeValueForKey:@"isExecuting"];
//        _executing = NO;
//        [self didChangeValueForKey:@"isExecuting"];
//        [self willChangeValueForKey:@"isFinished"];
//        _finished  = YES;
//        [self didChangeValueForKey:@"isFinished"];
//        NSLog(@"Finish executing %@", NSStringFromSelector(_cmd));
//    }
//    @catch (NSException *exception) {
//        NSLog(@"Exception: %@", exception);
//    }
//}
//@end


#define MAX_RECV_SIZE  2048
@interface SocketClient()
{
    
}

@property (nonatomic, assign) int socketFileDescriptor;
@property (nonatomic, strong) NSOperationQueue* operationQueue;
//@property (nonatomic, strong) SocketOperation* operation;

@property (nonatomic, assign) int connetSocketResult;
@property (nonatomic, assign) int sendTag;
@property (nonatomic, assign) int readTag;

@end

@implementation SocketClient

static SocketClient *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id) init {
    if (self = [super init]) {
        self.connetSocketResult = -2;
        self.sendTag = 0;
        self.readTag = 0;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    _operationQueue = nil;
    //_operation = nil;
    close(_socketFileDescriptor);
    _connetSocketResult = -1;
}

- (BOOL)connectToHost:(NSString*)host onPort:(uint16_t)port error:(NSError**)error {
    @autoreleasepool {
        if(self.connetSocketResult == 0) {
            [self startReceiveData];
            return YES;
        }
        // 创建 socket
        self.socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
        if (-1 == self.socketFileDescriptor) {
            NSLog(@"创建失败");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"socket创建失败", NSLocalizedDescriptionKey, @"失败原因：socket创建失败", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
            //[self.delegate socketDidDisconnect:self withError:err];
            *error = err;
            return NO;
        }
        // 客户端不需要bind
//        // 绑定 端口号
//        struct sockaddr_in addr;
//        memset(&addr,0, sizeof(addr));
//        addr.sin_len = sizeof(addr);
//        addr.sin_family = AF_INET;
//
//        addr.sin_addr.s_addr = INADDR_ANY;
//        int ret = bind(self.socketFileDescriptor,  (const struct sockaddr *)&addr, sizeof(addr));
//        if (-1 == ret) {
//            NSLog(@"bind失败");
//            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"socket bind失败", NSLocalizedDescriptionKey, @"失败原因：socket bind失败", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
//            NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
//            //[self.delegate socketDidDisconnect:self withError:err];
//            *error = err;
//
//            return -1;
//        }
//        NSLog(@"bind成功");
        
        // 获取 IP 地址
        struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
        if (NULL == remoteHostEnt) {
            close(self.socketFileDescriptor);
            NSLog(@"%@",@"无法解析服务器的主机名");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"无法解析服务器的主机名", NSLocalizedDescriptionKey, @"失败原因：无法解析服务器的主机名", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
            //[self.delegate socketDidDisconnect:self withError:err];
            *error = err;
            return NO;
        }
        struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
        // 设置 socket 参数
        struct sockaddr_in socketParameters;
        memset(&socketParameters, 0, sizeof(socketParameters));
        socketParameters.sin_family = AF_INET;
        socketParameters.sin_addr = *remoteInAddr;
        socketParameters.sin_port = htons(port);
        
        //int nosigpipe = 1;
        // 防止发送SO_NOSIGPIPE信号导致崩溃
        //int ret = setsockopt(self.socketFileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe,sizeof(nosigpipe));
//        if (-1 == ret) {
//            NSLog(@"SO_NOSIGPIPE信号");
//            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"SO_NOSIGPIPE信号", NSLocalizedDescriptionKey, @"失败原因：SO_NOSIGPIPE信号", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
//            NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
//            //[self.delegate socketDidDisconnect:self withError:err];
//            *error = err;
//            return NO;
//        }
        //unsigned long ul = 1;
        //ioctl(self.socketFileDescriptor, FIONBIO, &ul);
        // 连接 socket
        int ret = connect(self.socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
        if (-1 == ret) {
            close(self.socketFileDescriptor);
            NSLog(@"连接失败");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"socket连接失败", NSLocalizedDescriptionKey, @"失败原因：socket连接失败", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError *err = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:-1 userInfo:userInfo];
            [self.delegate socketDidDisconnect:self withError:err];
            *error = err;
            self.connetSocketResult = -1;
            return NO;
        }
        self.connetSocketResult = 0;
        NSLog(@"连接成功");
        [self.delegate socket:self didConnectToHost:host port:port];
        
        socklen_t addrLen;
        addrLen = sizeof(socketParameters);
        // 获取套接字信息
        ret = getsockname(self.socketFileDescriptor, (struct sockaddr *)&socketParameters, &addrLen);
        
        if (-1 == ret) {
            NSLog(@"获取套接字信息失败");
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"获取套接字信息失败", NSLocalizedDescriptionKey, @"失败原因：获取套接字信息失败", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
            *error = err;
            return NO;
        }
        NSLog(@"获取套接字信息成功");
    }
    
    [self startReceiveData];
    return YES;
}

- (void)sendData:(NSData*)data
{
    if(self.connetSocketResult != 0) {
        return;
    }
    size_t size = data.length;
    size_t ret = send(self.socketFileDescriptor, [data bytes], size , 0);
    if (-1 == ret) {
        NSLog(@"send 失败");
    }else {
        self.sendTag ++;
        [self.delegate socket:self didWriteDataWithTag:self.sendTag];
    }
}

- (BOOL)isConnnect
{
    return (self.connetSocketResult == 0);
}

-(void)startReceiveData {
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    WEAKSELF;
    [self.operationQueue addOperationWithBlock:^{
        [weakself receiveData];
    }];
}

- (void)stop
{
    [_operationQueue cancelAllOperations];
    _operationQueue = nil;
}

- (void)disconnect {
    [self stop];
    close(self.socketFileDescriptor);
    self.connetSocketResult = -1;
}

- (void)receiveData
{
    if(self.connetSocketResult != 0) {
        return;
    }
    struct fd_set fds;
    struct timeval timeout={5,0}; //select等待5秒，5秒轮询，要非阻塞就置0
    char buf[MAX_RECV_SIZE] = {0};
    while(1) {
        FD_ZERO(&fds); //每次循环都要清空集合，否则不能检测描述符变化
        FD_SET(self.socketFileDescriptor,&fds); //添加描述符
        switch(select(self.socketFileDescriptor+1,&fds,&fds,NULL,&timeout)) //select使用
        {
            case -1:
            {
                memset(&buf, 0, MAX_RECV_SIZE);
                [self disconnect];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"socket 断开", NSLocalizedDescriptionKey, @"失败原因：socket 断开", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
                NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
                [self.delegate socketDidDisconnect:self withError:err];
                break; //select错误，退出程序
            }
            case 0: // timeout handled
                
                break; //再次轮询
            default:
            {
                if(FD_ISSET(self.socketFileDescriptor,&fds)) {
                    long size = recv(self.socketFileDescriptor, buf,sizeof(buf), 0);
                    printf("接收socket数据%s\n",buf);
                    if (size <= 0) {
                        memset(&buf, 0, MAX_RECV_SIZE);
                        [self disconnect];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"socket 断开", NSLocalizedDescriptionKey, @"失败原因：socket 断开", NSLocalizedFailureReasonErrorKey, @"恢复建议：请重新连接",NSLocalizedRecoverySuggestionErrorKey,nil];
                        NSError *err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:-1 userInfo:userInfo];
                        [self.delegate socketDidDisconnect:self withError:err];
                        return;
                    }
                    NSData* chatMsg = [NSData dataWithBytes:buf length:size];
                    msg_header_t pch = (msg_header_t)[chatMsg bytes];
                    if (size >= MSG_HEADER_SIZE && size >= pch->len)
                    {
                        NSData* d = [chatMsg subdataWithRange:NSMakeRange(0, pch->len)];
                        pch = (msg_header_t)[d bytes];
                        if (pch->cmd == CMD_CHAT && pch->subcmd == CHATCMD_CHANNEL_CHAT)
                        {
                            msg_chatmsg_t chatmsg = (msg_chatmsg_t)(pch + 1);
                            printf("接收socket数据内容 : %s\n",chatmsg->content);
                            NSData* data = [[NSData alloc] initWithBytes:chatmsg->content length:chatmsg->content_len];
                            self.readTag ++;
                            [self.delegate socket:self didReadData:data uid:chatmsg->uid withTag:self.readTag];
                            memset(&buf, 0, MAX_RECV_SIZE);
                        }
                        else if (pch->cmd == CMD_CHAT && pch->subcmd == CHATCMD_ERRCODE)
                        {
                            msg_errcode_ex_t errmsg = (msg_errcode_ex_t)(pch);
                            if (errmsg->code == ECLIENT_AUTHOK)
                            {
                                NSLog(@"ECLIENT_AUTHOK");
                            }
                        }
                    }
                }
            }
        }
    }
}

@end

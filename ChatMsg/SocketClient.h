//
//  SocketClient.h
//  student
//
//  Created by Stephen on 2018/6/1.
//  Copyright © 2018年 YiMi. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SocketClient;

@protocol SocketClientDelegate <NSObject>
- (void)socketDidDisconnect:(SocketClient *)sock withError:(NSError *)err;
- (void)socket:(SocketClient *)sock didConnectToHost:(NSString *)host port:(uint16_t)port;
- (void)socket:(SocketClient *)sock didReadData:(NSData *)data uid:(int)fromUID withTag:(long)tag;
- (void)socket:(SocketClient *)sock didWriteDataWithTag:(long)tag;
- (NSTimeInterval)socket:(SocketClient *)sock
shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length;
- (NSTimeInterval)socket:(SocketClient *)sock
shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length;
@end

@interface SocketClient : NSObject

@property (nonatomic, weak) id<SocketClientDelegate> delegate;
@property (nonatomic, readonly) BOOL isConnected;

+ (instancetype)sharedInstance;
- (void)disconnect;
- (void)sendData:(NSData*)data;

- (BOOL)connectToHost:(NSString*)host onPort:(uint16_t)port error:(NSError**)error;

@end

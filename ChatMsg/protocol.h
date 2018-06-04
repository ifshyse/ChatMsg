#ifndef __PROTOCOL_H__
#define	__PROTOCOL_H__

#ifdef __cplusplus
extern "C" {
#endif


#ifndef _WIN32
#define GetLastError() errno
typedef unsigned char byte;
#endif

typedef	uint16_t ushort;

#pragma pack(1)


// 字符串传送格式
struct string_st
{
	ushort	len;	// str len
	char	str[0];
};
typedef struct string_st *string_t;

struct msg_header_st
{
	ushort	len;
	byte	cmd;	// cmd里面其实放的是消息的分类，或者类似于分类的意思
					// cmd可以分成移动，聊天，战斗，修练，物品。。。。

	byte	subcmd;	// subcmd就可以到具体的消息
					// 比如移动可以有：走动，奔跑，传送。。。
					// 可以尽量抽取共性，这样也可以少定义一些结构
					// 比如走动，奔跑，传送，应该是可以用一个结构处理的
};

#define MSG_HEADER_SIZE		4
#define MAX_PACK_SIZE       1000
#define MSG_MAX_SIZE		MAX_PACK_SIZE

// 取得协议头后面的数据
#define msg_data(pheader)	((char*)(pheader)+MSG_HEADER_SIZE)

// 可能相关的结构

// 人物移动：走动，奔跑，传送
struct msg_move_st
{
	ushort	scene_id;	// 场景编号/地图编号
	ushort	x;
	ushort	y;
};

// 聊天发送方：频道聊天user_id为0、
struct msg_chatmsg_st
{
	int		uid;	// user_id: ToUid（接收者）/ Uid（发送者）该字段用于转发消息。
	int		channel_id;	// 私聊channel_id为0
	ushort	msg_id;	// 消息标识
	ushort	content_len;	// content长度, content_len <= CHAT_CONTENT_MAXLEN
	char	content[0];		// CHAT_CONTENT_MAXLEN, 不包括字符串结尾0
};

#define	CHAT_CONTENT_MAXLEN		1000

#define	AUTH_KEY_MAXLEN		64
#define	NICKNAME_MAXLEN		32	// usernick name max len
//聊天管理模块接口
struct msg_data_array_st
{
	int count;			//数组大小
	int *content;			//数组
};
//聊天管理模块查询
//1.指定用户内的频道列表，2.频道内的用户id列表，3.地图内的用户id列表，4.用户列表，5.频道列表，6.地图列表时使用的一个cid，mapid，或者uid
struct msg_query_list_st
{
	int id;	
};

// 取用户信息（暂时只有昵称）
struct msg_get_userinfo_st
{
	int		uid;
};

struct msg_get_userinfo_ret_st
{
	int		uid;
	ushort	nick_len;	// nick长度, nick_len <= NICKNAME_MAXLEN
	char	nick[0];		// NICKNAME_MAXLEN, 不包括字符串结尾0
};

// 频道管理
struct msg_channel_st
{
	int	uid;
	ushort	level;
	ushort	resv;	
	int	channel_id;
};

//设定用户权限:CHATCMD_SET_PRIV 0x05
#define	OP_SET_PRIV		0
// 设置指定时间内禁止登陆
#define	OP_BAN_USER_LOGIN		1
//设置指定时间内禁言
#define	OP_BAN_USER_CHAT		2
//直接踢出该用户一次，用户重新登陆即可
#define OP_BAN_USER_KICK_ONCE		3

// 用户管理, 操作已经上线过的人
struct msg_setpriv_st
{
	int	uid;
	ushort	op;	// 设置权限，删除用户等。。。OP_SET_PRIV    OP_BAN_USER 踢人
	ushort	level;
	int	sec;	// 禁言时长，仅level＝LV_NONE有效，单位：秒
};

#define	OP_BAN_IP_LOGIN		4
#define	OP_BAN_IP_CHAT		5
#define OP_BAN_IP_KICK_ONCE		6
//踢出当前用户id对应的ip的所有用户！
#define OP_BAN_IP_LOGIN_BY_USERID		7
#define OP_BAN_IP_CHAT_BY_USERID		8
#define OP_BAN_IP_KICK_ONCE_BY_USERID		9
// 禁IP（段） + 时间
//ip和mask字节序：127.0.0.1和255.255.255.0在发送数据包中的字节顺序为：0x7f,0x0,0x0.x01,0xff,0xff,0xff,0x0
struct msg_ban_ip_st
{
	int	op;		// ban ip/ip LV_NONE
	int	ip;		// 限制指定uid的ip时，此值为uid！
	int	mask;	// 按照子网掩码规则
	int	sec;	// 禁止时长，单位：秒
};
// 进入频道，同时允许加入多个，方便初始化
struct msg_channel_n_st
{
	int	uid;
	int	channel_num;
	int	channel_ids[1];
};

struct msg_auth_st
{
	int	uid;	// 系统用户（GameServer，监控终端）必须为0
	//ushort	level; // 上线信息已经有msg_userinfo_st
	ushort	key_len;	// key长度, key_len <= AUTH_KEY_MAXLEN, 注意key_len溢出（即长度超过包剩余长度）
	char	key[0];		// AUTH_KEY_MAXLEN, 不包括字符串结尾0
};

// GS发送用户上线信息
struct msg_userinfo_st
{
	int	uid;	// 系统用户（GameServer，监控终端）必须为0
	ushort	level;
	//ushort	nick_len;
	char	nick[NICKNAME_MAXLEN];
	ushort	key_len;	// key长度, key_len <= AUTH_KEY_MAXLEN, 注意key_len溢出（即长度超过包剩余长度）
	char	key[0];		// AUTH_KEY_MAXLEN, 不包括字符串结尾0
};

struct msg_errcode_st
{
	struct msg_header_st	header;
	int code;
};
//struct msg_chatmsg_ret_st
//{
//	ushort	msg_id;	// 消息标识
//	ushort	errcode;	// msg send error code: 找不到频道/找不到用户。。。
//};

struct msg_channel_ret_st
{
	struct msg_header_st	header;//操作：CHATCMD_CHANNEL_DISMISS，CHATCMD_CHANNEL_LEAVE，CHATCMD_CHANNEL_JOIN
	int	uid;
	int	channel_id;	
};
struct msg_errcode_ex_st
{
	struct msg_header_st	header;
	int code;
	int lasterror;	//具体的网络错误码！通过getlasterror()获得。如：10048，10054....
};
//struct msg_chatmsg_ret_ex_st
//{
//	ushort	msg_id;	// 消息标识
//	ushort	errcode;	// msg send error code: 找不到频道/找不到用户。。。
//	int lasterror;	//具体的网络错误码！通过getlasterror()获得。如：10048，10054....
//};
//任意数据转发结构：处理系统公告，用户代理消息，其它游戏专用消息
struct msg_transfer_data_st
{
	int id;				// 频道id，用户id根据命令号区分
	ushort	data_len;	// 数据长度
	//ushort	data_id;	// 数据标识，为0时，可以把数据长度做为一个整数对待。
	//int data_len;		// 数据长度
	char data[1];		// 具体数据
};

// 用户验证数据，临时使用
typedef struct user_auth_key_st
{
	int channelid;
	struct string_st name;
}*user_auth_key_t;

#pragma pack()

typedef	struct msg_header_st * msg_header_t;
typedef	struct msg_chatmsg_st *	msg_chatmsg_t;
typedef	struct msg_channel_st * msg_channel_t;
typedef	struct msg_channel_n_st * msg_channel_n_t;
typedef	struct msg_channel_ret_st * msg_channel_ret_t;

typedef	struct msg_auth_st * msg_auth_t;
typedef	struct msg_userinfo_st * msg_userinfo_t;
//typedef	struct msg_chatmsg_ret_st * msg_chatmsg_ret_t;
typedef	struct msg_setpriv_st * msg_setpriv_t;
typedef	struct msg_errcode_st * msg_errcode_t;
typedef	struct msg_errcode_ex_st * msg_errcode_ex_t;
//typedef	struct msg_chatmsg_ret_ex_st * msg_chatmsg_ret_ex_t;
typedef	struct msg_get_userinfo_st * msg_get_userinfo_t;
typedef	struct msg_get_userinfo_ret_st * msg_get_userinfo_ret_t;
typedef	struct msg_ban_ip_st * msg_ban_ip_t;
typedef	struct msg_data_array_st * msg_data_array_t;
typedef	struct msg_query_list_st * msg_query_list_t;
typedef	struct msg_transfer_data_st * msg_transfer_data_t;

// 聊天子命令号
#define CMD_CHAT	3
// 最大命令ID+1
#define	CHATCMD_MAX				0x20
//定义目前已经使用的所有cmdid
enum PACKET_CMD_CHAT_ID
{
	CHATCMD_UNKNOWN = 0,
	//消息返回码：
	CHATCMD_ERRCODE,		//= 0x01		
	// GameServer验证：命令号	msg_auth_st
	CHATCMD_SERV_LOGIN_AUTH,	//= 0x02	
	// GameServer发送玩家KEY：对应结构 msg_userinfo_st
	CHATCMD_SET_USER_KEY,		//= 0x03
	// 玩家验证：对应结构	msg_auth_st
	CHATCMD_USER_LOGIN_AUTH,	//= 0x04
	// 设置玩家权限：对应结构	msg_setpriv_st
	CHATCMD_SET_USER_LEVEL,		//=	0x05

	// 客户端心跳：对应结构 无，只有协议头
	CHATCMD_HEART_BEAT,			//= 0x06

	// 私聊：对应结构	msg_chatmsg_st
	CHATCMD_PRIVATE_CHAT,		//= 0x07
	// 频道聊天：对应结构	msg_chatmsg_st
	CHATCMD_CHANNEL_CHAT,		//= 0x08
	
	// 创建频道：对应结构	msg_channel_st
	CHATCMD_CHANNEL_CREATE,	//=	0x09
	// 解散频道：对应结构	msg_channel_st
	CHATCMD_CHANNEL_DISMISS,//=	0x0A
	// 加入频道：对应结构	msg_channel_n_st
	CHATCMD_CHANNEL_JOIN,	//=	0x0B
	// 退出频道：对应结构	msg_channel_st
	CHATCMD_CHANNEL_LEAVE,	//=	0x0C
	// 获取指定频道内的所有用户id列表:msg_query_list_st,返回：msg_data_array_st
	CHATCMD_GET_CHANNEL_USERID_LIST,	//	0x0D
	// 获取指定用户id所加入的所有频道列表：msg_query_list_st
	CHATCMD_GET_USER_CHANNEL_LIST,	//=	0x0E

	//对ip进行限制：禁止登陆，禁言，踢出所有用户一次操作：msg_ban_ip_st
	CHATCMD_SET_IP_LIMIT,	//= 0x0F
	//根据用户id获取用户昵称//// 取用户昵称：对应结构	msg_get_userinfo_t	msg_get_userinfo_ret_t
	CHATCMD_GET_USER_NICKNAME,		//=	0x10

	//向频道和世界转发系统数据（任意数据）：对应结构	msg_transfer_data_st
	CHATCMD_TRANSFER_CHANNEL_DATA,	//= 0x11
	//向指定用户转发系统数据（任意数据）：对应结构	msg_transfer_data_st
	CHATCMD_TRANSFER_USER_DATA,		//=	0x12


};
//定义返回给客户端的子命令号
//默认返回格式为：
//主命令号为：CHATCMD_ERRCODE + 子命令号 + 每一个子命令号对应的具体信息。
//每一个子命令号对应的具体信息:包括网络错误码，时间，更新后的权限等内容。
enum PACKET_RETURN_ERROR_CODE
{
// client error codes
	ECLIENT_NOERROR =	0x0000,
	ECLIENT_NOUSER	= 0x0101,	// 不存在或不在线
	ECLIENT_SENDFAILED,	
	ECLIENT_OFFLINE,		// 用户下线，前面查找用户是在线的
	ECLIENT_NOPRIV	,		// 没有权限
	ECLIENT_NOCHANNEL,		// 不存在
	ECLIENT_NOTINCHAN,		// 不在频道内
	ECLIENT_AUTHFAILED,	
	ECLIENT_AUTHOK	,		//256 +8 = 264

// server errors
	ESERVER_ERRDATA	,
	ESERVER_AUTHOK	,
	ESERVER_CHANNELFAILED,

	ESEND_ALREADY_SEND,
	//通用错误
	ECOMMON_OUT_OF_MEMORY,
	ECOMMON_NO_ENOUGH_SIZE ,
	//定义解析命令码错误
	ECOMMON_CMD_ID_ERROR,
	//定义由于该ip被禁止登陆的错误号,后面的错误信息为剩余禁止登陆时间！
	ECOMMON_LIMIT_IP_LOGIN,
	//定义由于该uid被禁止登陆的错误号,后面的错误信息为剩余禁止登陆时间！
	ECOMMON_LIMIT_USER_LOGIN ,
	//定义由于该ip被禁言的错误号,后面的错误信息为剩余时间！
	ECOMMON_LIMIT_IP_CHAT,
	//定义由于该uid被禁言的错误号,后面的错误信息为剩余时间！
	ECOMMON_LIMIT_USER_CHAT,
	//定义由于相同账号的用户登陆导致当前用户被踢下线
	ECOMMON_UID_LOGIN_AGAIN ,
	//定义用户权限被修改:CHATCMD_SET_PRIV = 5向用户设置后，对该用户的回复。
	ECOMMON_USER_LEVEL_CHANGED,

	//定义主命令码错误或者数据包解析错误！
	ECOMMON_PACKET_CHECK_FAILED,

	//定义用户发言次数太多，请稍候重试！
	ECLIENT_CHAT_TOO_QUICK,

};





#ifdef __cplusplus
}	// end extern C
#endif

#endif	// __PROTOCOL_H__

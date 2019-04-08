### 本文档包含的API是针对单帐号的，如果需要多账号统一管理API，请移步到[Controller-API](Controller-API.md)

### API列表汇总

|API地址                      |可用状态 |API说明        |
|:----------------------------|:-------|:--------------|
|微信基础信息获取相关           |       |                |
|[/openwx/get_user_info](API.md#获取用户数据)      |running |获取登录用户数据 |
|[/openwx/get_friend_info](API.md#获取好友数据)  |running |获取好友数据 |
|[/openwx/get_group_info](API.md#获取群组数据)       |running |获取群组数据 |
|[/openwx/get_group_basic_info](API.md#获取群组基本数据)       |running |获取群组基本数据 |
|[/openwx/get_avatar](API.md#获取用户或群组头像)          |running |获取用户或群组头像|
|数据搜索相关                  |        |                |
|[/openwx/search_friend](API.md#搜索好友对象)        |running |搜索好友对象|
|[/openwx/search_group](API.md#搜索群组对象)        |running |搜索群组对象|
|聊天控制相关                  |        |                |
|[/openwx/create_group](API.md#创建群组)         |running |创建群组         |
|[/openwx/invite_friend](API.md#邀请好友加入群组)        |running |邀请好友加入群组|
|[/openwx/make_friend](API.md#向指定的群成员发送好友请求)          |running |向指定的群成员发送好友请求|
|[/openwx/set_group_displayname](API.md#设置群组的显示名称)|running |设置群组的显示名称|
|[/openwx/kick_group_member](API.md#移除群组成员)    |running |移除群组成员|
|[/openwx/set_markname](API.md#修改好友或群成员备注名称)         |running |修改好友或群成员备注名称|
|[/openwx/stick](API.md#设置或取消聊天置顶)                |running |设置或取消群组、好友置顶|
|[/openwx/accept_friend_request](API.md#接受好友验证申请)                |running |接受好友验证申请|
|发送消息相关                  |        |                |
|[/openwx/send_friend_message](API.md#发送好友消息)  |running |发送好友消息     |
|[/openwx/send_group_message](API.md#发送群组消息)   |running |发送群组消息     |
|[/openwx/revoke_message](API.md#撤回消息)   |running |撤回消息     |
|[/openwx/upload_media](API.md#上传媒体文件)         |running |上传媒体文件，获取media_id, 用于稍后发送     |
|[/openwx/consult](API.md#好友问答)              |running  |发送消息给好友并返回好友的回复<br>主要用途是转发微软小冰的智能回复|
|事件（消息）获取相关 |                    |         |
|[自定义事件（消息）上报地址](API.md#自定义事件消息上报地址) |scaning<br>updating<br>running| 将产生的事件通过HTTP POST请求发送到指定的地址<br>可用于上报扫描二维码事件、新增好友事件、接收消息事件等 |
|[/openwx/check_event](API.md#查询事件消息) |running| 采用HTTP GET请求长轮询机制获取事件（消息）<br>API只能工作在非阻塞模式下，功能受限<br>不如POST上报的方式获取的信息全面 |
|客户端控制相关                |        |                |
|[/openwx/get_client_info](API.md#获取程序运行信息)      |running |获取程序运行信息|
|[/openwx/stop_client](API.md#终止程序运行)          |running |终止程序运行   |

### 首先启动一个API Server：

可以直接把如下代码保存成一个源码文件(必须使用UTF8编码)，使用 perl 解释器来运行

```
    #!/usr/bin/env perl
    use Mojo::Weixin;
    my ($host,$port,$post_api,$poll_api);
    
    $host = "0.0.0.0"; #发送消息接口监听地址，没有特殊需要请不要修改
    $port = 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
    #$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行
    #$poll_api = 'http://xxxx';  #心跳请求地址，默认注释或删掉此行，更多说明参见下文 心跳请求 相关文档
    
    my $client = Mojo::Weixin->new(log_level=>"info",http_debug=>0);
    $client->load("ShowMsg");
    $client->load("Openwx",data=>{
        listen => [{host=>$host,port=>$port}],       #可选，发送消息api监听端口
        post_api=> $post_api,                        #可选，接收消息或事件的上报地址
        post_event => 1,                             #可选，是否上报事件，为了向后兼容性，默认值为0
        post_media_data => 0,                        #可选，是否上报经过base64编码的图片原始数据，默认值为1
        post_event_list => ['login','stop','state_change','input_qrcode'], #可选，上报事件列表，更多说明参考下文 事件上报 相关文档
        poll_api  => $poll_api,                      #可选，心跳请求地址，默认不启用
        poll_interval   => 5,                        #可选，长轮询请求间隔，默认5s
    });
    $client->run();
    
```
API是通过加载`Openwx插件`的形式提供的，上述代码保存成 xxxx.pl 文件

然后使用 perl 来运行，就会完成 微信 登录并在本机产生一个监听指定地址端口的 http server

    $ perl xxxx.pl

### 客户端数据文件介绍

微信客户端在运行过程中会产生很多的文件，这些文件默认情况下会保存在系统的临时目录下

你可以通过在启动脚本的 `Mojo::Weixin->new()`中增加 `tmpdir` 参数来修改这个临时目录的位置，例如：

    Mojo::Weixin->new(log_level=>"info",http_debug=>0,tmpdir=>'C:\tmpdir\') #请确保目录已经存在并有访问权限

更多自定义参数参见[Mojo::Weixin->new参数说明](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod#new)

    mojo_weixin_cookie_{客户端名称}.dat #客户端的cookie文件，用于短时间内重复登录免扫码
    mojo_weixin_pid_{客户端名称}.pid    #记录客户端进程号，防止相同微信帐号产生多个重复的客户端实例
    mojo_weixin_qrcode_{客户端名称}.jpg #客户端登录二维码文件
    mojo_weixin_state_{客户端名称}.json #客户端的运行状态相关的信息，json格式，实时更新

一般情况下你不需要关心这些文件保存在哪里，有什么作用，这些文件也会在程序退出的时候自动进行清理

### 客户端运行状态介绍

客户端运行过程中会在多种状态之间切换，有很多状态是阻塞的，相当于一个死循环，需要达到一定条件才能跳出死循环

单帐号模式采用的是单进程异步机制，API全部都是工作在非阻塞模式下，因此在阻塞的状态中API（发送消息/接收消息等）都是暂时无法工作的

比如： 在登录扫描的状态下，还没有完成登录，是无法调用API去发送消息，请求会收不到任何响应

了解客户端这些状态的差异，有助于帮助你合理正确的调用API

|   状态      |模式        |状态说明
|------------|------------|:-------------------------------------------------|
|init        | -          |客户端创建后的初始状态                              |
|loading     |blocking    |客户端加载插件                                     |
|scaning     |blocking    |等待手机扫码                                       |
|confirming  |blocking    |等待手机点击[登录]按钮                              |
|updating    |blocking    |更新个人、好友、群组信息                            |
|running     |non-blocking|客户端运行中，可以正常接收、发送消息，**相关API可以工作**  |
|stop        |-           |客户端停止运行                                     |

客户端状态的一般迁移过程：

`init` => `loading` => `scaning` => `confirming` => `updating` => `running` => `stop`

客户端状态实时更新到 `mojo_weixin_state_{客户端名称}.json` 文件中，可以通过读取这个文件来获取上述相关状态的变化

也可以通过客户端 [事件上报](API.md#事件上报) 中的 `state_change` 事件来获取客户端当前所处的状态

多账号模式下也可以通过Controller提供的 `/openwx/check_client` 接口查询到这个状态

（`/openwx/check_client`接口实际上就是返回  `mojo_weixin_state_{客户端名称}.json` 文件中的数据 ）

### 关于心跳请求的说明

可能用于内网穿透、客户端存活检测、客户端信息收集等方面，期待你发掘更多利用价值

设置 `Openwx插件` 中的参数 `poll_api`和`poll_interval`，会使得客户端在处于 `running` 状态时，自发的去请求`poll_api`地址

期望的是，这个请求会长时间阻塞等待，服务端不返回任何数据（服务端逻辑需要你自己去实现）

服务端响应结果或者请求超时断开后，会间隔`poll_interval` 秒后继续重复发起请求，如此往复

如果你的程序是部署在内网环境，而又希望通过外网的服务器去调用内网的api，实现发送消息等功能

当外网的服务端希望内网的客户端程序调用某个api接口时，比如希望内网的客户端调用`/openwx/send_friend_message`接口给指定的好友发消息

服务端通过HTTP协议的302 Location返回需要访问的完整api地址 

    http://127.0.0.1:3000/openwx/send_friend_message?id=xxx&content=xxxx

客户端收到302的响应后会自动请求跳转后的地址（客户端自己请求自己本机127.0.0.1的api地址）实现发送消息

```
> GET /poll_url HTTP/1.1
> User-Agent: curl/7.29.0
> Host: www.example.com
> Accept: */*
> 
< HTTP/1.1 302 Found
< Location: http://127.0.0.1:3000/openwx/send_friend_message?id=filehelper&content=hello
< Date: Tue, 08 Nov 2016 14:00:15 GMT
< Content-Length: 0

```

### 获取用户数据
|   API  |获取用户数据
|--------|:------------------------------------------|
|uri     |/openwx/get_user_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_user_info|

返回数据:

```
    {
        "account": "xxx",
        "name": "xxx",
        "markname": "",
        "sex": "none",
        "display": "",
        "city": "",
        "signature": "帮助解决微信支付中遇到的困难，收集关于微信支付的建议反馈。",
        "province": "广东",
        "id": "@efc5f86c30df4b9c80e98ac428e0e257",
        "uid": 123,
        "displayname": "xxx"
    },
```

### 获取好友数据
|   API  |获取好友数据
|--------|:------------------------------------------|
|uri     |/openwx/get_friend_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_friend_info|
返回JSON数组:
```
[#好友数组
    {#第一个好友
        "account": "wxzhifu",
        "name": "微信支付",
        "category":"公众号",
        "markname": "",
        "sex": "none",
        "display": "",
        "city": "",
        "signature": "帮助解决微信支付中遇到的困难，收集关于微信支付的建议反馈。",
        "province": "广东",
        "id": "@efc5f86c30df4b9c80e98ac428e0e257",
        "uid": 123456,
        "displayname": "微信支付"
    },
    {#第二个好友
        "account": "",
        "name": "小灰",
        "category":"好友",
        "markname": "",
        "sex": "none",
        "display": "",
        "city": "深圳",
        "signature": "小灰灰的个性签名",
        "province": "广东",
        "id": "@00227d73fa6b8326f69bca419db7a05c",
        "uid": 123456,
        "displayname": "小灰"
    }
]
```

### 获取群组数据
|   API  |获取群组数据
|--------|:------------------------------------------|
|uri     |/openwx/get_group_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_group_info|
返回JSON数组:
```
[#群数组
    {#第一个群
        "name": "",
        "id": "@@dadadadada",
        "uid": 123456,
        "displayname": "xxxx"
        "member": [#群成员数组
            {#第一个群成员
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@adadada",
                "uid": 123456,
                "displayname": "xxx"
            },
            {#第二个群成员
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@dadada",
                "uid": 123456,
                "displayname": "xxx"
            },
        ],

    },
    {#第二个群组
        "name": "xxxx",
        "id": "@@dadadada",
        "uid": 123456,
        "displayname": "xxx"
        "member": [
            {
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@dadadada",
                "uid": 123456,
                "displayname": "xxx"
            },
            {
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@dadadada",
                "displayname": "xxx"
            },
        ],

    },
]
```

### 获取群组基本数据
|   API  |获取群组基本数据（不包含群成员）
|--------|:------------------------------------------|
|uri     |/openwx/get_group_basic_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_group_basic_info|


### 发送好友消息
|   API  |发送好友消息
|--------|:------------------------------------------|
|uri     |/openwx/send_friend_message|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>**content**:发送的文本内容(中文需要做urlencode)<br>**media_id**:媒体id(发送媒体消息返回的媒体id，需要做urlencode)<br>**media_path**:媒体路径(可以是文件路径或url，需要做urlencode)<br>**async**: 0或1,可选,是否异步发送消息|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/send_friend_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openwx/send_friend_message?markname=xxx&content=%e4%bd%a0%e5%a5%bd<br>http://127.0.0.1:3000/openwx/send_friend_message?id=xxx&media_path=https%3a%2f%2fss0.bdstatic.com%2flogo.png<br>http://127.0.0.1:3000/openwx/send_friend_message?id=xxx&media_id=%40crypt_1eb0ba44_cb3de736e6ccd5ae8%3a3|
特殊处理：id=@all 表示群发消息给所有的好友

#### 文本消息返回JSON数据格式:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
#### 媒体消息返回的JSON数据格式：
```
{"status":"发送成功","msg_id":23910327,"media_id":"@crypt_1eb0ba44_cb3de736e6ccd5ae8:3","code":0} #code为 0 表示发送成功
```
注意：相同媒体消息转发给多个好友或群组时，可以直接拿之前发送消息返回的media_id作为发送对象，这样可以避免重复上传文件，提高发送效率

如果不关心发送消息是否成功，可以采用异步发送的方式，调用接口马上返回:

```http://127.0.0.1:3000/openwx/send_group_message?id=xxxx&content=hello&async=1```

### 发送群组消息
|   API  |发送群组消息
|--------|:------------------------------------------|
|uri     |/openwx/send_group_message|
|请求方法|GET\|POST|
|请求参数|**id**: 群组的id<br>**displayname**: 群组显示名称<br>**content**:发送的文本内容(中文需要做urlencode)<br>**media_id**:媒体id(发送媒体消息返回的媒体id，需要做urlencode)<br>**media_path**:媒体路径(可以是文件路径或url，需要做urlencode)<br>**async**: 0或1,可选,是否异步发送消息|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/send_group_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openwx/send_group_message?displayname=xxx&content=%e4%bd%a0%e5%a5%bd<br>http://127.0.0.1:3000/openwx/send_group_message?id=xxx&media_path=https%3a%2f%2fss0.bdstatic.com%2flogo.png<br>http://127.0.0.1:3000/openwx/send_group_message?displayname=xxx&media_path=https%3a%2f%2fss0.bdstatic.com%2flogo.png<br>http://127.0.0.1:3000/openwx/send_group_message?id=xxx&media_id=%40crypt_1eb0ba44_cb3de736e6ccd5ae8%3a3|

#### 文本消息返回JSON数据格式:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
#### 媒体消息返回的JSON数据格式：
```
{"status":"发送成功","msg_id":23910327,"media_id":"@crypt_1eb0ba44_cb3de736e6ccd5ae8:3","code":0} #code为 0 表示发送成功
```
注意：相同媒体消息转发给多个好友或群组时，可以直接拿之前发送消息返回的media_id作为发送对象，这样可以避免重复上传文件，提高发送效率

如果不关心发送消息是否成功，可以采用异步发送的方式，调用接口马上返回:

```http://127.0.0.1:3000/openwx/send_group_message?id=xxxx&content=hello&async=1```

### 撤回消息
|   API  |撤回消息
|--------|:------------------------------------------|
|uri     |/openwx/revoke_message|
|请求方法|GET\|POST|
|请求参数|**id**: 消息的id|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/revoke_message?id=xxxx|

### 查询事件消息

| API|采用HTTP GET请求长轮询获取事件（消息）
|----|:------------------|
|uri |/openwx/check_event|
|请求方法|GET|
|数据格式|application/json|

接口返回JSON数组的形式，数组中的每个元素是一个JSON格式消息，格式和 [自定义事件消息上报地址](API.md#自定义事件消息上报地址) 完全一样

程序最大保留最近20条信息记录，可以通过插件参数`check_event_list_max_size`进行自定义

```
$client->load("Openwx",data=>{ 
    check_event_list_max_size=>100,
});
```

采用长轮询机制，没有事件（消息）时，请求会挂起等待30s即断开，需要客户端再次重复发起请求

API只能工作在非阻塞模式下,功能受限，不如POST上报的方式获取的信息全面，目前仅支持获取:

发送消息、接收消息 以及如下一部分事件: 

`new_group`,`new_friend`,`new_group_member`,`lose_group`,`lose_friend`,`lose_group_member`,`friend_request`

```
* Connected to 127.1 (127.0.0.1) port 3000 (#0)
> GET /openwx/check_event? HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.1:3000
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: application/json;charset=UTF-8
< Date: Tue, 22 Nov 2016 04:11:36 GMT
< Content-Length: 16405
< Server: Mojolicious (Perl)

[ 
   {
    "class":"send",
    "content":" hello world",
    "format":"text",
    "from":"none",
    "id":"2647366348175870091",
    "post_type":"send_message",
    "receiver":"文件传输助手",
    "receiver_account":"",
    "receiver_id":"filehelper",
    "receiver_name":"文件传输助手",
    "receiver_uid":"",
    "sender":"小灰",
    "sender_markname":"xxx",
    "sender_category":"系统帐号", #系统帐号|公众号|好友
    "time":"1479787946",
    "type":"friend_message"
    }
]
```

没有消息等待超时后，会返回一个空的JSON数组，客户端需要再次发起请求

```
* Connected to 127.1 (127.0.0.1) port 3000 (#0)
> GET /openwx/check_event? HTTP/1.1
> User-Agent: curl/7.29.0
> Host: 127.1:3000
> Accept: */*
> 
< HTTP/1.1 200 OK
< Content-Type: application/json;charset=UTF-8
< Date: Tue, 22 Nov 2016 04:11:36 GMT
< Content-Length: 16405
< Server: Mojolicious (Perl)

[]
```

### 自定义事件消息上报地址

|   API  |自定义事件（消息）上报地址
|--------|:------------------------------------------|
|uri     |自定义任意支持http协议的url|
|请求方法|POST|
|数据格式|application/json|

需要加载Openwx插件时通过 `post_api` 参数来指定上报地址:

```
$client->load("Openwx",data=>{
    listen => [{host=>xxx,port=>xxx}],           #可选，发送消息api监听端口
    post_api=> 'http://127.0.0.1:3000/post_api', #可选，接收消息或事件的上报地址
    post_event => 1,                             #可选，是否上报事件，为了向后兼容性，默认值为1
    post_stdout => 0,                            #可选，上报数据是否打印到stdout，适合管道交互信息方式，默认0
    post_media_data => 1,                        #可选，是否上报经过base64编码的图片原始数据，默认值为1
    post_event_list => ['login','stop','state_change','input_qrcode'], #可选，上报事件列表
    #post_message_filter => {class => "recv", "type" => "friend_message",format=>"app",sender_name=>"微信支付"},#可选，消息过滤
});
```

首先要了解消息一些关键属性信息：

上报或拉取的JSON数据的类型中的`post_type`属性用于区分上报的数据是消息类的数据还是其他事件

|关键属性     |取值             |说明                  | 
|:-----------|:----------------|:---------------------|
|post_type   |receive_message<br>send_message<br>event|接收消息<br>发送消息<br>其他事件|

发送接收消息（`post_type`为`receive_message`或`send_message`时)的关键属性信息：

|关键属性     |取值           |说明                           | 
|:-----------|:--------------|:------------------------------|
|id          |-|消息的id
|type        |friend_message<br>group_message<br>group_notice|消息类型细分:<br>好友消息<br>群消息<br>群提示消息  |
|class       |send<br>recv|表明是发送消息还是接收消息
|format      |text<br>media<br>app<br>revoke<br>card|消息的格式：<br>文本消息<br>媒体（图片、视频、语音）<br>应用分享<br>撤回消息<br>名片分享|
|sender_id   |-|消息发送者id（注意不是所有的消息类型都存在这个属性）
|receiver_id |-|消息接收者id（注意不是所有的消息类型都存在这个属性）
|group_id    |-|消息相关的群组id（注意不是所有的消息类型都存在这个属性）


#### 接收消息上报 

当接收到消息时，会把消息通过JSON格式数据POST到该接口

可以在Openwx插件中，通过 post_message_filter 参数来过滤上报的消息内容, 支持对消息中的任意多个属性进行过滤

```
$client->load("Openwx",data=>{
    listen => [{host=>xxx,port=>xxx}],           #可选，发送消息api监听端口
    post_api=> 'http://127.0.0.1:3000/post_api', #可选，接收消息或事件的上报地址
    post_message_filter => {class => "recv", "type" => "friend_message",format=>"app",sender_name=>"微信支付"},#仅上报微信支付消息
});
```

普通好友消息或群消息上报

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{   "receiver":"小灰",
    "time":"1442542632",
    "content":"测试一下",
    "class":"recv",
    "sender_id":"@2372835507",
    "sender_uid": 123456,
    "receiver_id":"@4072574066",
    "receiver_name": "小灰",
    "receiver_uid": 123456,
    "group":"PERL学习交流",
    "group_id":"@@2617047292",
    "group_uid": 123456,
    "group_name": "PERL学习交流",
    "sender":"灰灰",
    "sender_name": "灰灰",
    "id":"10856",
    "uid": 123456,
    "type":"group_message",
    "format": "text",
    "post_type": "receive_message"
}

```

#### 群提示消息上报

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{   "receiver":"小灰",
    "time":"1442542632",
    "content":"你邀请灰太狼加入了群聊",
    "class":"recv",
    "receiver_id":"@4072574066",
    "receiver_name":"小灰",
    "receiver_uid":123456,
    "group":"PERL学习交流",
    "group_name":"PERL学习交流",
    "group_id":"@@2617047292",
    "id":"10856",
    "type":"group_notice",
    "format": "text",
    "post_type": "receive_message"
}

```

#### 发送消息上报（包括从手机或其他设备上发送的消息） 

发送的消息会通过JSON格式数据POST到该接口

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{   "receiver":"小灰",
    "time":"1442542632",
    "content":"测试一下",
    "class":"send",
    "sender_id":"@2372835507",
    "receiver_id":"@4072574066",
    "receiver_uid":123456,
    "receiver_name":"小灰",
    "group":"PERL学习交流",
    "group_id":"@@2617047292",
    "group_name":"PERL学习交流",
    "group_uid":123456,
    "sender":"灰灰",
    "sender_uid":123456,
    "sender_name":"灰灰",
    "id":"10856",
    "type":"group_message",
    "format": "text",
    "post_type": "send_message"
}

```

#### 图片消息上报

```
{   "receiver":"小灰",
    "time":"1442542632",
    "content":"[media](\/tmp\/mojo_weixin_media_Ja9l.jpg)",
    "media_path": "\/tmp\/mojo_weixin_media_Ja9l.jpg",
    "media_id": "2273934420223351581",
    "media_mime":"image\/jpg",
    "media_name": "mojo_weixin_media_Ja9l.jpg",
    "media_size": "1234567",
    "media_mtime": "1462763788",
    "media_ext": "jpg",
    "media_data": "pXA88GiUcCncmxUgt2JbJxRVu2\/1j0U2xJH\/\/2Q==\n", #对图片原始二进制数据，使用base64默认方式编码
    "class":"recv",
    "sender_id":"@2372835507",
    "receiver_id":"@4072574066",
    "receiver_uid":"",
    "receiver_name":"",
    "group":"PERL学习交流",
    "group_id":"@@2617047292",
    "group_name":"",
    "group_uid":"",
    "sender":"灰灰",
    "sender_name":"",
    "sender_uid":"",
    "id":"10856",
    "type":"group_message",
    "format": "media",
    "post_type": "receive_message"
}

```

#### 应用分享消息上报

```
{   "receiver":"小灰",
    "receiver_uid":"",
    "receiver_name":"",
    "time":"1442542632",
    "content":"[应用分享]标题：饿了么给你发红包",
    "app_name":"饿了么",
    "app_id":"wx123456",
    "app_title":"饿了么给你发红包",
    "app_desc":"撩拨你的深夜味蕾，第2份半价！"
    "app_url":"https:\/\/h.ele.me\/hongbao", 
    "class":"recv",
    "sender_id":"@2372835507",
    "receiver_id":"@4072574066",
    "group":"PERL学习交流",
    "group_id":"@@2617047292",
    "group_uid":"",
    "group_name":"",
    "sender":"灰灰",
    "sender_uid":"",
    "sender_name":"",
    "id":"10856",
    "type":"group_message",
    "format": "app",
    "post_type": "receive_message"
}

```
#### 撤回消息上报

```
{
    "time":"1442542632",
    "content":"[撤回消息](你撤回了一条消息)",
    "revoke_id":"2513410439052032973", #被用户撤回的消息id
    "class":"send",
    "sender_id":"@2372835507",
    "sender_uid": 123456,
    "group":"PERL学习交流",
    "group_id":"@@2617047292",
    "group_uid": 123456,
    "group_name": "PERL学习交流",
    "sender":"灰灰",
    "sender_name": "灰灰",
    "id":"10856",
    "uid": 123456,
    "type":"group_message",
    "format": "revoke",
    "post_type": "send_message"
}

```

### 名片消息上报

```
{
    'card_avatar' => 'http://wx.qlogo.cn/mmhead/ver_1/k99g2RHrEeib9KMhGmXZGSIGDjgnmiaX2acT2wl04so2ibsq8ysVPRkRRNQyRLmUVptBpcHt6lvUZym5JgOSd4fug/0',
    'card_id' => '@bc9b2967ec91315f4dd47e5e3d0e33ee'
    'card_account' => '',
    'card_city' => '中国',
    'card_province' => '上海',
    'card_name' => 'xxx',
    'card_sex' => 'male',
    'sender_id' => '@b2c5637bb8e158a5a29eca00ac9ed0f9',
    'receiver_id' => 'filehelper',
    'id' => '5604497552796809997',
    'format' => 'card',
    'type' => 'friend_message',
    'class' => 'send',
    'time' => '1482985638',
}

```

一般情况下，post_api接口返回的响应内容可以是随意，会被忽略，上报完不做其他操作
如果post_api接口返回的数据类型是 text/json 或者 application/json，并且json格式形式如下:

```
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json;charset=UTF-8
Date: Mon, 29 Feb 2016 05:53:31 GMT
Content-Length: 27
Server: Mojolicious (Perl)

{"reply":"你好","code":0} #要回复消息，必须包含reply的属性，其他属性有无并不重要

```

则表示希望通过post_api响应的内容来直接回复该消息，会直接对上报的该条消息进行回复，回复的内容为 "你好"

如果想要对消息回复图片内容，可以使用 media 参数，举例:

```

{"media":"http://www.baidu.com/test.jpg","code":0}                          #使用url地址形式
{"media":"/tmp/test.jpg","code":0}                                          #使用本地文件地址形式
{"reply":"给你发个图片","media":"http://www.baidu.com/test.jpg","code":0}   #文本和图片同时发送

```

#### 其他非消息类事件上报

当事件发生时，会把事件相关信息上报到指定的接口，当前支持上报的事件包括：

|  事件名称                    |事件说明    |上报参数列表
|------------------------------|:-----------|:-----------------------------------------|
|login                         |客户端登录  | *1*：表示经过二维码扫描，好友等id可能会发生变化<br>*0*： 表示未经过二维码扫描，好友等id不会发生变化<br>*-1*：表示登录异常，第二个参数包含异常原因
|stop                          |客户端停止    | 客户端停止运行，程序退出
|state_change                  |客户端状态变化|旧的状态，新的状态 （参见[客户端状态说明](https://github.com/sjdy521/Mojo-Weixin/blob/master/Controller-API.md#客户端运行状态介绍)）
|input_qrcode                  |扫描二维码  | 二维码本地保存路径，二维码原始数据的base64编码
|new_group                     |新加入群聊  | 对应群对象
|new_friend                    |新增好友    | 对应好友对象
|new_group_member              |新增群聊成员| 对应成员对象，对应的群对象
|lose_group                    |退出群聊    | 对应群对象
|lose_friend                   |删除好友    | 对应好友对象
|lose_group_member             |成员退出群聊| 对应成员对象，对应的群对象
|group_property_change         |群聊属性变化| 群对象，属性，原始值，更新值
|group_member_property_change  |成员属性变化| 成员对象，属性，原始值，更新值
|friend_property_change        |好友属性变化| 好友对象，属性，原始值，更新值
|user_property_change          |帐号属性变化| 账户对象，属性，原始值，更新值
|update_user                   |初始化(更新)帐号信息|帐号对象
|update_friend                 |初始化(更新)好友信息|好友对象列表
|update_group                  |初始化(更新)群组信息|群组对象列表
|friend_request                |好友验证申请

可以在Openwx插件中，通过 `post_event_list` 参数来指定上报的事件

默认 `post_event_list => ['login','stop','state_change','input_qrcode','new_group','new_friend','new_group_member','lose_group','lose_friend','lose_group_member','friend_request']`

需要注意：属性变化类的事件可能触发的会比较频繁，导致产生大量的上报请求，默认不开启

初始化(更新）帐号信息事件

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{
    "post_type":"event",
    "event":"update_user",
    "params":[
        {
            "account": "xxx",
            "name": "xxx",
            "markname": "",
            "sex": "none",
            "display": "",
            "city": "",
            "signature": "帮助解决微信支付中遇到的困难，收集关于微信支付的建议反馈。",
            "province": "广东",
            "id": "@efc5f86c30df4b9c80e98ac428e0e257",
            "uid": 123,
            "displayname": "xxx"
       }
    ],

}

```

新增好友事件举例

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{
    "post_type":"event",
    "event":"new_friend",
    "params":[
        {
            "account":"ms-xiaoice",
            "name":"小冰",
            "markname":"",
            "sex":"0",
            "city":"海淀",
            "signature":"我是人工智能微软小冰，我回来了，吼吼~~",
            "province":"北京",
            "displayname":"小冰",
            "id":"@75b9db5ae52c87361d1800eaaf307f4d"
        }
    ],

}

```

扫描二维码事件举例

```
connect to 127.0.0.1 port 3000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{
    "post_type":"event",
    "event":"input_qrcode",
    "params":[
        {
            "\/tmp\/qrcode.jpg", #二维码本地路径
            "\/9j\/4AAQSkZJRgABAQAAAQABAAD\...UUUUUUUUUUUV\/\/Z\n", #二维码原始数据经过base64默认方式编码
        }
    ],

}

```

好友验证申请事件

```
{
    "post_type":"event",
    "event":"friend_request",
    "params":[
        "@75ab55c416dbe3a", #申请者的id
        "小灰", #申请者的显示名称
        "小灰请求加你为好友", #申请者的验证信息
        "v2_85c00f264eed801fee7@stranger" #接受好友验证申请时需要用到的ticket
    ]
}

```

**可以通过上报的json数组中的`post_type`来区分上报的数据是消息还是其他事件**

### 好友问答
|   API  |发送消息给好友并等待好友回答
|--------|:------------------------------------------|
|uri     |/openwx/consult|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>**timeout**：等待回复的时间，默认30秒<br>**media_path**:媒体路径(可以是文件路径或url，需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/consult?displayname=小冰&content=haha<br>http://127.0.0.1:3000/openwx/consult?displayname=%e5%b0%8f%e5%86%b0&media_path=%2ftmp%2fhello.jpg|

主要应用场景是把小冰(中文名称做urlencode: %e5%b0%8f%e5%86%b0)的智能回复封装成接口，给小冰发好友消息前，你需要先关注小冰的公众号
```
GET /openwx/consult?displayname=%e5%b0%8f%e5%86%b0&content=haha HTTP/1.1
User-Agent: curl/7.29.0
Host: 127.0.0.1:3000
Accept: */*

HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Date: Tue, 01 Mar 2016 07:25:11 GMT
Content-Length: 94
Server: Mojolicious (Perl)

{"reply":"哈哈，有什么事情","status":"发送成功","msg_id":"2683625013724723712","code":0}

超时失败时的返回结果：

{"reply":null,"reply_status":"reply timeout","status":"发送成功","msg_id":1456817344504,"code":0}
```

### 搜索好友对象
|   API  |搜索好友对象
|--------|:------------------------------------------|
|uri     |/openwx/search_friend|
|请求方法|GET\|POST|
|请求参数|好友对象的任意属性，中文需要做urlencode，比如：<br>**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/search_friend?id=xxxxxx<br>http://127.0.0.1:3000/openwx/search_friend?province=xxxxxx&city=xxxx|
返回JSON数组:

```
[#好友数组
    {#第一个好友
        "account": "wxzhifu",
        "name": "微信支付",
        "markname": "",
        "sex": "none",
        "display": "",
        "city": "",
        "signature": "帮助解决微信支付中遇到的困难，收集关于微信支付的建议反馈。",
        "province": "广东",
        "id": "@efc5f86c30df4b9c80e98ac428e0e257",
        "displayname": "微信支付"
    },
    {#第二个好友
        "account": "",
        "name": "财付通",
        "markname": "",
        "sex": "none",
        "display": "",
        "city": "深圳",
        "signature": "会支付 会生活",
        "province": "广东",
        "id": "@00227d73fa6b8326f69bca419db7a05c",
        "displayname": "财付通"
    }
]
```

### 搜索群组对象
|   API  |搜索群组对象
|--------|:------------------------------------------|
|uri     |/openwx/search_group|
|请求方法|GET\|POST|
|请求参数|群对象的任意属性，中文需要做urlencode，比如：<br>**id**: 群组的id<br>**displayname**: 群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/search_group?id=xxxxxx<br>http://127.0.0.1:3000/openwx/search_group?displayname=xxxxx|
返回JSON数组:

```
[#群数组
    {#第一个群
        "name": "",
        "id": "@@dadadadada",
        "displayname": "xxxx"
        "member": [#群成员数组
            {#第一个群成员
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@adadada",
                "displayname": "xxx"
            },
            {#第二个群成员
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@dadada",
                "displayname": "xxx"
            },
        ],

    },
    {#第二个群组
        "name": "xxxx",
        "id": "@@dadadada",
        "displayname": "xxx"
        "member": [
            {
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@dadadada",
                "displayname": "xxx"
            },
            {
                "account": "",
                "name": "xxx",
                "markname": "",
                "sex": "none",
                "display": "",
                "city": "",
                "signature": "",
                "province": "",
                "id": "@dadadada",
                "displayname": "xxx"
            },
        ],

    },
]
```

### 创建群组
|   API  |创建群组
|--------|:------------------------------------------|
|uri     |/openwx/create_group|
|请求方法|GET\|POST|
|请求参数|**friends**: 好友的id（多个好友id用逗号分割）<br>**displayname**: 可选，群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/create_group?displayname=xxxxxx&friends=xxxx,xxxx|
返回JSON结果:

```
{
    "group_id":"@@a6588c3bfa8b5458ffc8d758ae851d3f40f396c2ebc970d006a365fdbb5299e1", #创建的群组id
    "status":"success",
    "code":0  #创建成功状态码为0，失败为非0
}
```

### 邀请好友加入群组
|   API  |邀请好友加入群组
|--------|:------------------------------------------|
|uri     |/openwx/invite_friend|
|请求方法|GET\|POST|
|请求参数|**friends**: 好友的id（多个好友id用逗号分割）<br>**id**: 群组对象的id<br>**displayname**: 群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/invite_friend?id=xxxxxx&friends=xxxx,xxxx<br>http://127.0.0.1:3000/openwx/invite_friend?displayname=xxxxxx&friends=xxxx,xxxx|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}
```

### 移除群组成员

|   API  |移除群组成员
|--------|:------------------------------------------|
|uri     |/openwx/kick_group_member|
|请求方法|GET\|POST|
|请求参数|**members**: 成员的id（多个成员id用逗号分割）<br>**id**: 群组的id<br>**displayname**: 群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/kick_group_member?id=xxxxxx&members=xxxx,xxxx<br>http://127.0.0.1:3000/openwx/kick_group_member?displayname=xxxxxx&members=xxxx,xxxx|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}

```

### 修改好友或群成员备注名称

|   API  |修改好友或群成员备注名称（修改群成员备注的功能疑似被官方屏蔽）
|--------|:------------------------------------------|
|uri     |/openwx/set_markname|
|请求方法|GET\|POST|
|请求参数|**id**: 好友或群成员的id<br>**account**: 好友的帐号<br>**displayname**: 好友当前显示名称<br>**markname**: 好友当前备注名称<br>**new_markname**:设置的新备注名称 (参数中包含中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/set_markname?id=xxxxxx&new_markname=xxxx<br>http://127.0.0.1:3000/openwx/set_markname?account=xxxxxx&new_markname=xxxx<br>http://127.0.0.1:3000/openwx/set_markname?id=xxxxxx&group_id=xxxx&new_markname=xxxx|

注意：修改群成员备注的功能疑似被官方屏蔽，api调用即使返回成功可能也没有真正的生效，建议暂时不要使用

返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}

```

### 设置或取消聊天置顶

|   API  |设置或取消群组、好友置顶
|--------|:------------------------------------------|
|uri     |/openwx/stick|
|请求方法|GET\|POST|
|请求参数|**id**: 群组或好友的id<br>**op**:  1表示置顶,0表示取消置顶|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/stick?id=xxxxxx&op=1<br>http://127.0.0.1:3000/openwx/stick?id=xxxxxx&op=0|

返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}
```

### 设置群组的显示名称

|   API  |设置群组的显示名称
|--------|:------------------------------------------|
|uri     |/openwx/set_group_displayname|
|请求方法|GET\|POST|
|请求参数|**id**: 群组的id<br>**displayname**: 群组当前显示名称<br>**new_displayname**:设置的新显示名称 (参数中包含中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/set_group_displayname?id=xxxxxx&new_displayname=xxxx|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}

```

### 向指定的群成员发送好友请求

|   API  |向指定的群成员发送好友请求
|--------|:------------------------------------------|
|uri     |/openwx/make_friend|
|请求方法|GET\|POST|
|请求参数|**id**: 群成员的id<br>**verify**:好友请求的附加信息 (参数中包含中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/make_friend?id=xxxxxx&verify=hello|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}

```

### 获取用户或群组头像

|   API  |获取用户或群组头像
|--------|:------------------------------------------|
|uri     |/openwx/get_avatar|
|请求方法|GET\|POST|
|请求参数|**id**: 用户或群组的id<br>**group_id**: 群组id（获取群成员头像时需要用到,但群成员因为经常获取不到地址可能导致无法获取头像）|
|数据格式|image/jpg、image/png|
|调用示例|获取好友或群组头像: http://127.0.0.1:3000/openwx/get_avatar?id=xxxxxx<br>获取群成员头像:http://127.0.0.1:3000/openwx/get_avatar?id=xxxxxx&group_id=xxxxx|

返回图片原始数据:

```
GET /openwx/get_avatar?id=xxxxx HTTP/1.1
User-Agent: curl/7.29.0
Host: 127.0.0.1:3000
Accept: */*

HTTP/1.1 200 OK
Content-Type: image/jpg
Date: Tue, 09 Aug 2016 01:49:14 GMT
Content-Length: 1104
Server: Mojolicious (Perl)

```

### 获取程序运行信息

|   API  |获取进程运行信息
|--------|:------------------------------------------|
|uri     |/openwx/get_client_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_client_info|

返回JSON结果:

```
{
    "code":0,
    "account":"default",
    "log_encoding":null,
    "log_level":"debug",
    "log_path":null,
    "os":"linux",
    "pid":15497,
    "runtime":3096,
    "starttime":1475135588,
    "status":"success",
    "http_debug":"0",
    "version":"1.2.0"
 }
 ```
 
### 终止程序运行

|   API  |终止程序运行
|--------|:------------------------------------------|
|uri     |/openwx/stop_client|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/stop_client|

返回JSON结果:

```
{
    "code":0,
    "account":"default",
    "pid":15972,
    "runtime":30,
    "starttime":1475136637,
    "status":"success, client(15972) will stop in 3 seconds"
}
```

### 上传媒体文件

|   API  |上传媒体文件，获取media_id, 用于稍后发送
|--------|:------------------------------------------|
|uri     |/openwx/upload_media|
|请求方法|GET\|POST|
|请求参数|**media_path**: 媒体的路径，可以是本地路径或url地址|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/upload_media?media_path=%2ftmp%2ftest.mp4|

返回JSON结果:

```
{
    "media_ext":"mp4",
    "media_id":"@crypt_5e8967c8_e637847b7d0b00xxxxxxcb82:43",
    "media_mime":"video\/mp4",
    "media_mtime":1470650887,
    "media_name":"\/tmp\/test.mp4",
    "media_path":"\/tmp\/test.mp4",
    "media_size":66947
}
```

### 接受好友验证申请

|   API  |接受好友验证申请
|--------|:------------------------------------------|
|uri     |/openwx/accept_friend_request|
|请求方法|GET\|POST|
|请求参数|**id**: 申请者id（frient_request事件中会提供）<br>**displayname**：申请者显示名称（frient_request事件中会提供,中文需要urlencode）<br>**ticket**：接受申请需要的ticket（frient_request事件中会提供）|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/accept_friend_request?id=xxx&displayname=%85%c0%0f%2b&ticket=xxx|

返回JSON结果:

```
{
    "code": 0,
    "status": "success",
    "id": "xxx",
    "displayname": "xxx",
    "ticket": "xxx"
}
```

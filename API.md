### 本文档包含的API是针对单帐号的，如果需要多账号统一管理API，请移步到[Controller-API](Controller-API.md)

### 首先要启动一个API Server：

可以直接把如下代码保存成一个源码文件(必须使用UTF8编码)，使用 perl 解释器来运行

    #!/usr/bin/env perl
    use Mojo::Weixin;
    my ($host,$port,$post_api);
    
    $host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
    $port = 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
    #$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行
    
    my $client = Mojo::Weixin->new(log_level=>"info",http_debug=>0);
    $client->load("ShowMsg");
    $client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
    $client->run();

上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 微信 登录并在本机产生一个监听指定地址端口的 http server

    $ perl xxxx.pl

### 1. 获取用户数据
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

### 2. 获取好友数据
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

### 3. 获取群组数据
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
### 4. 发送好友消息
|   API  |发送好友消息
|--------|:------------------------------------------|
|uri     |/openwx/send_friend_message|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>**content**:发送的文本内容(中文需要做urlencode)<br>**media_id**:媒体id(发送媒体消息返回的媒体id，需要做urlencode)<br>**media_path**:媒体路径(可以是文件路径或url，需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/send_friend_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openwx/send_friend_message?markname=xxx&content=%e4%bd%a0%e5%a5%bd<br>http://127.0.0.1:3000/openwx/send_friend_message?id=xxx&media_path=https%3a%2f%2fss0.bdstatic.com%2flogo.png<br>http://127.0.0.1:3000/openwx/send_friend_message?id=xxx&media_id=%40crypt_1eb0ba44_cb3de736e6ccd5ae8%3a3|
特殊处理：id=@all 表示群发消息给所有的好友

####文本消息返回JSON数据格式:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
####媒体消息返回的JSON数据格式：
```
{"status":"发送成功","msg_id":23910327,"media_id":"@crypt_1eb0ba44_cb3de736e6ccd5ae8:3","code":0} #code为 0 表示发送成功
```
注意：相同媒体消息转发给多个好友或群组时，可以直接拿之前发送消息返回的media_id作为发送对象，这样可以避免重复上传文件，提高发送效率

### 5. 发送群组消息
|   API  |发送群组消息
|--------|:------------------------------------------|
|uri     |/openwx/send_group_message|
|请求方法|GET\|POST|
|请求参数|**id**: 群组的id<br>**displayname**: 群组显示名称<br>**content**:发送的文本内容(中文需要做urlencode)<br>**media_id**:媒体id(发送媒体消息返回的媒体id，需要做urlencode)<br>**media_path**:媒体路径(可以是文件路径或url，需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/send_group_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openwx/send_group_message?displayname=xxx&content=%e4%bd%a0%e5%a5%bd<br>http://127.0.0.1:3000/openwx/send_group_message?id=xxx&media_path=https%3a%2f%2fss0.bdstatic.com%2flogo.png<br>http://127.0.0.1:3000/openwx/send_group_message?displayname=xxx&media_path=https%3a%2f%2fss0.bdstatic.com%2flogo.png<br>http://127.0.0.1:3000/openwx/send_group_message?id=xxx&media_id=%40crypt_1eb0ba44_cb3de736e6ccd5ae8%3a3|

####文本消息返回JSON数据格式:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
####媒体消息返回的JSON数据格式：
```
{"status":"发送成功","msg_id":23910327,"media_id":"@crypt_1eb0ba44_cb3de736e6ccd5ae8:3","code":0} #code为 0 表示发送成功
```
注意：相同媒体消息转发给多个好友或群组时，可以直接拿之前发送消息返回的media_id作为发送对象，这样可以避免重复上传文件，提高发送效率
### 6. 自定义接收消息上报地址
|   API  |接收消息上报（支持好友消息、群消息）
|--------|:------------------------------------------|
|uri     |自定义任意支持http协议的url|
|请求方法|POST|
|数据格式|application/json|

需要加载Openwx插件时通过 `post_api` 参数来指定上报地址:
```
$client->load("Openwx",data=>{
    listen => [{host=>xxx,port=>xxx}],           #可选，发送消息api监听端口
    post_api=> 'http://127.0.0.1:3000/post_api', #可选，接收消息或事件的上报地址
    post_event => 1,                             #可选，是否上报事件，为了向后兼容性，默认值为0
    post_media_data => 1,                        #可选，是否上报经过base64编码的图片原始数据，默认值为1
    post_event_list => ['login','stop','state_change','input_qrcode'], #可选，上报事件列表
});
```
#### 接收消息上报 

当接收到消息时，会把消息通过JSON格式数据POST到该接口

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

群提示消息上报

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

#### 事件上报

当事件发生时，会把事件相关信息上报到指定的接口，当前支持上报的事件包括：

|  事件名称                    |事件说明    |上报参数列表
|------------------------------|:-----------|:-----------------------------------------|
|login                         |客户端登录  | *1*：表示经过二维码扫描，好友等id可能会发生变化<br>*0*： 表示未经过二维码扫描，好友等id不会发生变化
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

可以在Openwx插件中，通过 `post_event_list` 参数来指定上报的事件

默认 `post_event_list => ['login','stop','state_change','input_qrcode']`

需要注意：属性变化类的事件可能触发的会比较频繁，导致产生大量的上报请求，默认不开启

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

可以通过上报的json数组中的`post_type`来区分上报的数据数接收到的消息还是事件

### 7. 好友问答
|   API  |发送消息给好友并等待好友回答
|--------|:------------------------------------------|
|uri     |/openwx/consult|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>**timeout**：等待回复的时间，默认30秒<br>**media_path**:媒体路径(可以是文件路径或url，需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/consult?account=ms-xiaoice&content=haha<br>http://127.0.0.1:3000/openwx/consult?account=ms-xiaoice&media_path=%2ftmp%2fhello.jpg|

主要应用场景是把小冰(微信帐号ms-xiaoice)的智能回复封装成接口，给小冰发好友消息前，你需要先关注小冰的公众号
```
GET /openwx/consult?account=ms-xiaoice&content=haha HTTP/1.1
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

### 8. 搜索好友对象
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

### 9. 搜索群组对象
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

### 10. 创建群组
|   API  |创建群组
|--------|:------------------------------------------|
|uri     |/openwx/create_group|
|请求方法|GET\|POST|
|请求参数|**friend**: 好友的id（多个好友id用逗号分割）<br>**displayname**: 可选，群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/create_group?displayname=xxxxxx&friend=xxxx,xxxx|
返回JSON结果:

```
{
    "group_id":"@@a6588c3bfa8b5458ffc8d758ae851d3f40f396c2ebc970d006a365fdbb5299e1", #创建的群组id
    "status":"success",
    "code":0  #创建成功状态码为0，失败为非0
}
```

### 11. 邀请好友加入群组
|   API  |邀请好友加入群组
|--------|:------------------------------------------|
|uri     |/openwx/invite_friend|
|请求方法|GET\|POST|
|请求参数|**friend**: 好友的id（多个好友id用逗号分割）<br>**id**: 群组对象的id<br>**displayname**: 群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/invite_friend?id=xxxxxx&friend=xxxx,xxxx<br>http://127.0.0.1:3000/openwx/invite_friend?displayname=xxxxxx&friend=xxxx,xxxx|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}
```

### 11. 移除群组成员

|   API  |移除群组成员
|--------|:------------------------------------------|
|uri     |/openwx/kick_group_member|
|请求方法|GET\|POST|
|请求参数|**member**: 成员的id（多个成员id用逗号分割）<br>**id**: 群组的id<br>**displayname**: 群组的显示名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/kick_group_member?id=xxxxxx&member=xxxx,xxxx<br>http://127.0.0.1:3000/openwx/kick_group_member?displayname=xxxxxx&member=xxxx,xxxx|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}

```

### 12. 修改好友备注名称

|   API  |修改好友备注名称
|--------|:------------------------------------------|
|uri     |/openwx/set_friend_markname|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友当前显示名称<br>**markname**: 好友当前备注名称<br>**new_markname**:设置的新备注名称 (参数中包含中文需要做urlencode)|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/set_friend_markname?id=xxxxxx&new_markname=xxxx|
返回JSON结果:

```
{
    "status":"success",
    "code":0  #成功状态码为0，失败为非0
}

```

### 13. 设置群组的显示名称

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

### 14. 向指定的群成员发送好友请求

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

### 15. 获取用户或群组头像

|   API  |获取用户或群组头像
|--------|:------------------------------------------|
|uri     |/openwx/get_avatar|
|请求方法|GET\|POST|
|请求参数|**id**: 用户或群组的id|
|数据格式|image/jpg、image/png|
|调用示例|http://127.0.0.1:3000/openwx/get_avatar?id=xxxxxx|

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

### 16. 获取程序运行信息

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
 
### 17. 终止程序运行

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

### 18. 上传媒体文件

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

### 1. 获取用户数据
|   API  |获取用户数据
|--------|:------------------------------------------|
|url     |/openwx/get_user_info|
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
        "displayname": "xxx"
    },
```

### 2. 获取好友数据
|   API  |获取好友数据
|--------|:------------------------------------------|
|url     |/openwx/get_friend_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_friend_info|
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

### 3. 获取群组数据
|   API  |获取群组数据
|--------|:------------------------------------------|
|url     |/openwx/get_group_info|
|请求方法|GET\|POST|
|请求参数|无|
|调用示例|http://127.0.0.1:3000/openwx/get_group_info|
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
### 4. 发送好友消息
|   API  |发送好友消息
|--------|:------------------------------------------|
|url     |/openwx/send_friend_message|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/send_friend_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openwx/send_friend_message?markname=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
### 5. 发送群组消息
|   API  |发送群组消息
|--------|:------------------------------------------|
|url     |/openwx/send_group_message|
|请求方法|GET\|POST|
|请求参数|**id**: 群组的id<br>**displayname**: 群组显示名称|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/send_group_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openwx/send_group_message?markname=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```
### 6. 自定义接收消息上报地址
|   API  |接收消息上报（支持好友消息、群消息）
|--------|:------------------------------------------|
|url     |自定义任意支持http协议的url|
|请求方法|POST|
|数据格式|application/json|

需要加载Openwx插件时通过 `post_api` 参数来指定上报地址:
```
$client->load("Openwx",data=>{
    listen => [{host=>xxx,port=>xxx}],
    post_api=> 'http://127.0.0.1:4000/post_api',
});
```
当接收到消息时，会把消息通过JSON格式数据POST到该接口

```
connect to 127.0.0.1 port 4000
POST /post_api
Accept: */*
Content-Length: xxx
Content-Type: application/json

{   "receiver":"小灰",
    "time":"1442542632",
    "content":"测试一下",
    "class":"recv",
    "sender_id":"@2372835507",
    "receiver_id":"@4072574066",
    "group":"PERL学习交流",
    "group_id":"@@2617047292",
    "sender":"灰灰",
    "id":"10856",
    "type":"group_message"
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

### 7. 好友问答
|   API  |发送消息给好友并等待好友回答
|--------|:------------------------------------------|
|url     |/openwx/consult|
|请求方法|GET\|POST|
|请求参数|**id**: 好友的id<br>**account**: 好友的帐号<br>**displayname**: 好友显示名称<br>**markname**: 好友备注名称<br>**timeout**：等待回复的时间，默认30秒<br>|
|数据格式|application/x-www-form-urlencoded|
|调用示例|http://127.0.0.1:3000/openwx/consult?account=ms-xiaoice&content=haha|

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

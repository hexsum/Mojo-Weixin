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
|调用示例|http://127.0.0.1:3000/openwx/send_friend_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openqq/send_friend_message?markname=xxx&content=%e4%bd%a0%e5%a5%bd|
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
|调用示例|http://127.0.0.1:3000/openwx/send_group_message?id=xxxx&content=hello<br>http://127.0.0.1:3000/openqq/send_group_message?markname=xxx&content=%e4%bd%a0%e5%a5%bd|
返回JSON数组:
```
{"status":"发送成功","msg_id":23910327,"code":0} #code为 0 表示发送成功
```

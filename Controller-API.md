### 微信多账号管理API

* 支持多账号客户端的管理（启动、停止）
* 支持统一的API来查询帐号信息、发送消息、上报接收消息
* 兼容全部的单帐号API，仅在原有的单帐号API地址中增加 `client=xxx` 参数来识别不同帐号客户端


### 架构设计

采用多进程模型，主进程监听端口2000端口，对外提供统一的api请求服务，每个微信帐号是一个独立的子进程，分配一个单独的端口和主进程通信

linux中使用`ps ef`命令可以方便的查看到进程的运行情况

```
\_ wxcontroller #监听2000端口，提供统一的api服务               
	\_ wxclient(weixin_client_01) #子进程监听3000端口
	\_ wxclient(weixin_client_02) #子进程监听3001端口
	\_ wxclient(weixin_client_03) #子进程监听3002端口
	\_ wxclient(weixin_client_04) #子进程监听3003端口
```

### 首先要启动一个API Server：

可以直接把如下代码保存成一个源码文件(必须使用UTF8编码)，使用 perl 解释器来运行

    #!/usr/bin/env perl
    use Mojo::Weixin::Controller;
    my ($host,$port,$post_api);

    $host = "0.0.0.0"; #Controller API server 监听地址
    $port = 2000;      #Controller API server 监听端口，修改为自己希望监听的端口
    #$post_api = 'http://xxxx';  #每个微信帐号接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

    my $controller = Mojo::Weixin::Controller->new(
        listen              =>[{host=>$host,port=>$port} ], #监听的地址端口
        backend_start_port  => 3000, #可选，后端微信帐号分配的端口最小值
        post_api            => $post_api, #每个微信帐号上报的api地址
    #   tmpdir              => '/tmp', #可选，临时目录位置
    #   pid_path            => '/tmp/mojo_weixin_controller_process.pid', #可选，Controller进程的pid信息，默认tmpdir目录
    #   backend_path        => '/tmp/mojo_weixin_controller_backend.dat', #可选，后端微信帐号信息，默认tmpdir目录
    #   check_interval      => 5, #可选，检查后端微信帐号状态的时间间隔
    #   log_level           => 'debug',#可选,debug|info|warn|error|fatal
    #   log_path            => '/tmp/mojo_weixin_controller.log', #可选，运行日志路径，默认输出到终端
    #   log_encoding        => 'utf8', #可选，打印到终端的编码，默认自动识别
    );
    $controller->run();

上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 微信 登录并在本机产生一个监听指定地址端口的 http server

    $ perl xxxx.pl

### 启动一个微信客户端 

|   API  |启动一个微信客户端
|--------|:------------------------------------------|
|uri     |/openwx/start_client|
|请求方法|GET|
|请求参数|**client**: 自定义微信帐号，用于唯一区分不同微信帐号客户端<br>**其他Mojo-Weixin new方法支持的参数，比如log_level/log_encoding/tmpdir等等，详见 [Mojo::Weixin#new](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod#new)**|
|调用示例|http://127.0.0.1:2000/openwx/start_client?client=weixin_client_01<br>http://127.0.0.1:2000/openwx/start_client?client=weixin_client_01&log_level=debug|

返回JSON数据:
```
{"client":"weixin_client_01","code":0,"pid":32294,"port":3000,"status":"success"}
```

### 停止一个微信客户端 

|   API  |停止一个微信客户端
|--------|:------------------------------------------|
|uri     |/openwx/stop_client|
|请求方法|GET|
|请求参数|**client**: 自定义微信帐号，用于唯一区分不同微信帐号客户端|
|调用示例|http://127.0.0.1:2000/openwx/stop_client?client=weixin_client_01|

返回JSON数据:
```
{"client":"weixin_client_01","code":0,"pid":32294,"port":3000,"status":"success"}
```

### 查询所有微信客户端列表

|   API  |查询所有微信客户端列表
|--------|:------------------------------------------|
|uri     |/openwx/check_client|
|请求方法|GET|
|请求参数|无|
|调用示例|http://127.0.0.1:2000/openwx/check_client|

返回JSON数据:
```
[
    {"client":"weixin_client_01","pid":32294,"port":3000,"status":"success"},
    {"client":"weixin_client_02","pid":32295,"port":3001,"status":"success"},
]
```
### 其他微信帐号控制（查询信息、发送消息、上报消息等）

查询某个微信帐号的信息、发送消息、消息上报等和[单帐号模式API](API.md)相同，只是url中增加了一个 `client=xxx`的参数用于区分不同客户端，比如

####查询某个微信帐号用户信息:

http://127.0.0.1:2000/openwx/get_user_info?client=weixin_client_01

####使用某个微信帐号发送好友消息： 

http://127.0.0.1:2000/openwx/send_friend_message?client=weixin_client_01&id=filehelper&content=hello

每个微信帐号会独立上报消息，比如设置了上报消息post_api地址为 http://127.0.0.1/post_message

则每个帐号上报时会**自动带上client参数**用于区分不同客户端

POST http://127.0.0.1/post_message?client=weixin_client_01

POST http://127.0.0.1/post_message?client=weixin_client_02


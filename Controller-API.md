## 微信多账号管理API

* 支持多账号客户端的管理（启动、停止）
* 支持统一的API来查询帐号信息、发送消息、上报接收消息
* 兼容全部的单帐号API，仅在原有的单帐号API地址中增加 `client=xxx` 参数

## 首先要启动一个API Server：

可以直接把如下代码保存成一个源码文件(必须使用UTF8编码)，使用 perl 解释器来运行

    #!/usr/bin/env perl
    use Mojo::Weixin::Controller;
    my ($host,$port,$post_api);

    $host = "0.0.0.0"; #Controller API server 监听地址
    $port = 6000;      #Controller API server 监听端口，修改为自己希望监听的端口
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

## API 列表

### 启动一个微信客户端 

|   API  |启动一个微信客户端
|--------|:------------------------------------------|
|uri     |/openwx/start_client|
|请求方法|GET|
|请求参数|**client**:自定义微信帐号，用于唯一区分不同微信帐号客户端<br>**其他Mojo-Weixin new方法支持的参数**|
|调用示例|http://127.0.0.1:6000/openwx/start_client?client=weixin_client_01|

返回JSON数据:
```
{"client":"weixin_client_01","code":0,"pid":32294,"port":3000,"status":"success"}
```


Mojo-Weixin v1.0.3 [![Build Status](https://travis-ci.org/sjdy521/Mojo-Weixin.svg?branch=master)](https://travis-ci.org/sjdy521/Mojo-Weixin)
========================
使用Perl语言编写的微信客户端框架，基于Mojolicious，要求Perl版本5.10.1+，可通过插件提供基于HTTP协议的api接口供其他语言或系统调用

###郑重声明

本项目完全遵循网页微信官方提供的原始聊天功能，不包含任何破解、偷盗等行为，本项目完全开源，目的是为了促进技术交流学习，禁止任何商业盈利目的以及一切非法用途传播，否则后果自负

###插件列表
``` 
  名称                 优先级   当前状态    github作者    功能说明
  ------------------------------------------------------------------------------
  ShowMsg              100      已发布      sjdy521       打印客户端接收和发送的消息
  IRCShell             99       已发布      sjdy521       Linux环境下通过irc客户端使用qq
  Openwx               98       已发布      sjdy521       提供微信发送消息api接口
  Perlcode             97       已发布      sjdy521       通过微信消息执行perl代码
  Perldoc              96       已发布      sjdy521       通过微信消息查询perl文档
  Translation          93       已发布      sjdy521       多国语言翻译功能
  KnowledgeBase        2        已发布      sjdy521       通过微信消息自定义问答知识库
  FuckDaShen           1        已发布      sjdy521       对消息中的"大神"关键词进行鄙视
  PostQRcode           0        已发布      sjdy521       登录二维码发送到邮箱实现远程扫码
  SmartReply           0        已发布      sjdy521       智能聊天回复
```
###效果展示
```
[16/01/19 23:10:49] [info] 客户端准备登录...
[16/01/19 23:10:50] [info] 清除残留的历史二维码图片
[16/01/19 23:10:30] [info] 二维码已下载到本地[ /tmp/mojo_weixin_qrcode.png ]
[16/01/19 23:11:20] [info] 等待手机微信扫描二维码...
[16/01/19 23:12:09] [info] 手机微信扫码成功，请在手机微信上点击 [登录] 按钮...
[16/01/19 23:12:10] [info] 正在进行登录...
[16/01/19 23:12:10] [info] 微信登录成功
[16/01/19 23:13:40] [info] 获取联系人信息...
[16/01/19 23:13:40] [info] 更新个人信息成功
[16/01/19 23:14:41] [info] 更新好友信息成功
[16/01/19 23:15:42] [info] 更新群组[ 红包群 ]信息成功
[16/01/19 23:15:42] [info] 更新群组[ Perl语言交流 ]信息成功
[16/01/19 23:15:42] [info] 开始接收消息...
[16/01/19 23:15:00] [群消息] 小灰|Perl语言交流 : Mojo::Weixin不错哦
[16/01/19 23:15:58] [群消息] 我->Perl语言交流 : 多谢多谢
```
###通过irc客户端在linux终端上使用微信

![IRCShell](screenshot/IRCShell.jpg)

###安装方法

推荐使用[cpanm](https://metacpan.org/pod/distribution/App-cpanminus/bin/cpanm)在线安装[Mojo::Weixin](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod)模块 

1. *安装cpanm工具*

    方法a： 通过cpan安装cpanm

        $ cpan -i App::cpanminus
    
    方法b： 直接在线安装cpanm

        $ curl -kL http://cpanmin.us | perl - App::cpanminus

2. *使用cpanm在线安装 Mojo::Weixin 模块*

        $ cpanm -v Mojo::Weixin

3. *安装失败可能有帮助的解决方法*
        
    如果你运气不佳，通过cpanm没有一次性安装成功，这里提供了一些可能有用的信息

    在安装 Mojo::Weixin 的过程中，cpan或者cpanm会帮助我们自动安装很多其他的依赖模块
    
    在众多的依赖模块中，安装经常容易出现问题的主要是 IO::Socket::SSL
    
    IO::Socket::SSL 主要提供了 https 支持，在安装过程中可能会涉及到SSL相关库的编译

    对于 Linux 用户，通常采用的是编译安装的方式，系统缺少编译安装必要的环境，则会导致编译失败
    
    对于 Windows 用户，由于不具备良好的编译安装环境，推荐采用一些已经打包比较全面的Perl运行环境
    
    例如比较流行的 strawberryperl 或者 activeperl 的最新版本都默认包含 Mojo::Weixin 的核心依赖模块

    RedHat/Centos:

        $ yum install -y openssl-devel
        
    Ubuntu:

        $ sudo apt-get install libssl-dev

    Window:
        
    这里以 strawberryperl 为例

    安装 [Strawberry Perl](http://strawberryperl.com/)，这是一个已经包含 [Mojo::Weixin](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod) 所需核心依赖的较全面的Windows Perl运行环境 
    
    [32位系统安装包](http://strawberryperl.com/download/5.22.0.1/strawberry-perl-5.22.0.1-32bit.msi)
        
    [64位系统安装包](http://strawberryperl.com/download/5.22.0.1/strawberry-perl-5.22.0.1-64bit.msi)
        
    或者自己到 [Strawberry Perl官网](http://strawberryperl.com/) 下载适合自己的最新版本
    
    安装前最好先卸载系统中已经安装的其他Perl版本以免互相影响
    
    搞定了编译和运行环境之后，再重新回到 步骤2 安装Mojo::Weixin即可
        

###如何使用

1. *我对Perl很熟悉，是一个专业的Perler*

    该项目是一个纯粹的Perl模块，已经发布到了cpan上，请仔细阅读 `Mojo::Weixin` 模块的[使用文档](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod)

    除此之外，你可以看下 [demo](https://github.com/sjdy521/Mojo-Weixin/tree/master/demo) 目录下的更多代码示例

2. *我是对Perl不熟悉，是一个其他语言的开发者，只对提供的消息发送/接收接口感兴趣*

    可以直接把如下代码保存成一个源码文件，使用 perl 解释器来运行
    
        #!/usr/bin/env perl
        use Mojo::Weixin;
        my ($host,$port,$post_api);
        
        $host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
        $port = 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
        $post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除此行
        
        my $client = Mojo::Weixin->new(log_level=>"info",ua_debug=>0);
        $client->login();
        $client->load("ShowMsg");
        $client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
        $client->run();
    
    上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 QQ 登录并在本机产生一个监听指定地址端口的 http server
    
        $ perl xxxx.pl
    
    发送好友消息的接口调用示例
    
        http://127.0.0.1:3000/openwx/send_message?id=xxxx&content=hello
        
        * About to connect() to 127.0.0.1 port 3000 (#0)
        *   Trying 127.0.0.1...
        * Connected to 127.0.0.1 (127.0.0.1) port 3000 (#0)
        > GET /openwx/send_message?id=xxxxx&content=hello HTTP/1.1
        > User-Agent: curl/7.29.0
        > Host: 127.0.0.1:3000
        > Accept: */*
        > 
        < HTTP/1.1 200 OK
        < Content-Type: application/json;charset=UTF-8
        < Date: Sun, 13 Dec 2015 04:54:38 GMT
        < Content-Length: 52
        < Server: Mojolicious (Perl)
        <
        * Connection #0 to host 127.0.0.1 left intact
        
        {"status":"发送成功","msg_id":23910327,"code":0}
    
    更多接口参数说明参加[Openwx插件使用文档](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod#Mojo::Weixin::Plugin::Openwx)
    
###核心依赖模块

* [Mojolicious](https://metacpan.org/pod/Mojolicious)
* [Encode::Locale](https://metacpan.org/pod/Encode::Locale)

###相关文档

* [更新日志](https://github.com/sjdy521/Mojo-Weixin/blob/master/Changes)
* [开发文档](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod)

###官方交流

* [QQ群](http://jq.qq.com/?_wv=1027&k=kjVJzo)
* [IRC](http://irc.perfi.wang/?channel=#Mojo-Webqq)

###COPYRIGHT 和 LICENCE

Copyright (C) 2014 by sjdy521

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


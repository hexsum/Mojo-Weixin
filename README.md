Mojo-Weixin v1.1.6 [![Build Status](https://travis-ci.org/sjdy521/Mojo-Weixin.svg?branch=master)](https://travis-ci.org/sjdy521/Mojo-Weixin) [![Join the chat at https://gitter.im/sjdy521/Mojo-Weixin](https://badges.gitter.im/sjdy521/Mojo-Weixin.svg)](https://gitter.im/sjdy521/Mojo-Weixin?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
========================

使用Perl语言编写的微信客户端框架，基于Mojolicious，要求Perl版本5.10+，可通过插件提供基于HTTP协议的api接口供其他语言或系统调用

###郑重声明

本项目完全遵循网页微信官方提供的原始聊天功能，不包含任何破解、盗号等行为，本项目完全开源，目的是为了促进技术交流学习，禁止任何商业盈利目的以及一切非法用途传播，否则后果自负

###特色功能

* 支持 发送/接收文字、图片、视频、语音、表情、文件等多种媒体消息（网页版自身功能范围）
* 支持 新增/失去好友、新增/退出群组、新增/失去群成员 等事件提醒
* 支持 创建群组、群组加人/踢人、发送/接受好友验证申请、设置群组名称、设置好友备注
* 支持 Windows/Linux/Mac 多平台，支持docker镜像，易安装部署，不懂Perl也能用
* 提供 基于HTTP协议的API接口 ，简洁丰富，方便和其他编程语言集成
* 主人人品极好，你懂的

###插件列表

|名称                | 优先级  |当前状态    |github作者   | 功能说明  | 使用状态               
|:-------------------|:--------|:-----------|:------------|:----------------------------
|[ShowMsg](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::ShowMsg)             |100      |已发布      |sjdy521      |打印客户端接收和发送的消息
|[ImageStore](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::ImageStore)             |100      |已发布      |sjdy521      |按日期目录保存发送和接收的图片
|[IRCShell](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::IRCShell)            |99       |已发布      |sjdy521      |Linux环境下通过irc客户端使用微信
|[Openwx](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Openwx)              |98       |已发布      |sjdy521      |提供微信发送消息api接口
|[Perlcode](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Perlcode)            |97       |已发布      |sjdy521      |通过微信消息执行perl代码
|[Perldoc](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Perldoc)             | 96      |已发布      |sjdy521      |通过微信消息查询perl文档
|[Beauty](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Beauty)              |95       |已发布      |sjdy521      |识别指定关键字发送美女图片
|[Translation](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Translation)         |93       |已发布      |sjdy521      |多国语言翻译功能
|[Riddle](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Riddle)              |92       |已发布      |limengyu1990 |输入"猜谜"关键字进行猜谜游戏
|[Weather](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::Weather)             |91       |已发布      |autodataming |输入"北京天气"查询指定地区天气|不可用
|[KnowledgeBase](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::KnowledgeBase)       |2        |已发布      |sjdy521      | 通过微信消息自定义问答知识库
|[FuckDaShen](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::FuckDaShen)          |1        |已发布      |sjdy521      |对消息中的"大神"关键词进行鄙视
|[AutoVerify](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::AutoVerify)          |1        |已发布      |sjdy521      |收到好友验证请求时自动批准同意
|[PostQRcode](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::PostQRcode)          |0        |已发布      |sjdy521      |登录二维码发送到邮箱实现远程扫码
|[XiaoiceReply](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::XiaoiceReply)        |1        |已发布      |sjdy521      |利用微软小冰实现智能聊天回复
|[SmartReply](https://metacpan.org/pod/distribution/Mojo-Weixin/lib/Mojo/Weixin.pod#Mojo::Weixin::Plugin::SmartReply)          |0        |已发布      |sjdy521      |智能聊天回复


###效果展示

敲一行命令就能启动一个智能聊天机器人，Perl 和你都如此优雅. Enjoy!

    cpanm Mojo::Weixin && perl -MMojo::Weixin -e "Mojo::Weixin->new->load('ShowMsg')->load('SmartReply')->run()"
    
```
[16/01/19 23:10:49] [info] 客户端准备登录...
[16/01/19 23:10:50] [info] 清除残留的历史二维码图片
[16/01/19 23:10:30] [info] 二维码已下载到本地[ /tmp/mojo_weixin_qrcode.jpg ]
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

```
    +-------------------+                      +----------------+  
    |  Tencent          |                      | Any IRC Client |
    |  Weixin Server    |                      | wechat、irssi  |
    +---v-------------^-+                      +-v------------^-+     
        |             |                          |            |
        | 微信协议交互|                          |IRC协议交互 |
+-- --- |--  - -  --  | - - -   --   -  -   ---  | ---  ----- | --+
|   +---v-------------^--+                  +----v------------^-+ |   
|   |                    <——————————————————<                   | |
|   |   Weixin  Client   |  Weixin - IRC    |  IRC Server       | |
|   |                    |     协议转换     |  监听本机6667端口 | |
|   |                    >——————————————————>                   | | 
|   +--------------------+                  +-------------------+ |
|                                                                 |
|                                       我们程序实现的部分        | 
+---  - - - -  -- - --  ----  ------  -------  ------  ---    ----+

```

![IRCShell](screenshot/IRCShell.jpg)

###安装方法

推荐使用[cpanm](https://metacpan.org/pod/distribution/App-cpanminus/bin/cpanm)在线安装[Mojo::Weixin](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod)模块, 如果使用docker方式请参见[Docker镜像安装及使用方法](Docker.md)

1. *安装perl*
  
    安装之前请先确认下你的系统是否已经安装了Perl，因为除了windows，其他大部分的平台默认都可能已经预装过

    并且你的Perl版本至少5.10.1+，推荐5.14+

    [Perl官网下载页面](https://www.perl.org/get.html) 有包含Unix/Linux、Mac OS X、Windows多平台比较全面详细的安装说明

    建议大家尽量选择**Binaries**（二进制预编译）的版本，安装即可使用，比较方便

  |平台   |推荐选择|下载地址
  |-------|--------|-------------|
  |Windows|1. **StrawberryPerl**<br>2. ActivePerl<br>|[StrawberryPerl下载地址](http://strawberryperl.com/)<br>[ActivePerl下载地址](http://www.activestate.com/activeperl/downloads)|
  |Linux  |1. **ActivePerl**<br>2. 官方源码<br>3. yum/apt等包管理器<br>4. Mojo-ActivePerl|[ActivePerl下载地址](http://www.activestate.com/activeperl/downloads)<br>[Mojo-ActivePerl下载地址](https://github.com/sjdy521/Mojo-ActivePerl)|
  |Mac    |1. **ActivePerl**|[ActivePerl下载地址](http://www.activestate.com/activeperl/downloads)
  
    注意：[Mojo-ActivePerl](https://github.com/sjdy521/Mojo-ActivePerl)是我基于ActivePerl打包的而成
  
    已经包含perl-5.22+cpanm+Mojo-Webqq+Mojo-Weixin的完整运行环境，适用于linux x86_64系统，并且系统glibc 2.15+

2. *安装cpanm工具*（如果系统已经安装了cpanm可以忽略此步骤）

    方法a： 通过cpan安装cpanm

        $ cpan -i App::cpanminus
    
    方法b： 直接在线安装cpanm

        $ curl -kL http://cpanmin.us | perl - App::cpanminus

2. *使用cpanm在线安装 Mojo::Weixin 模块*（如果系统已经安装了该模块，执行此步骤会对模块进行升级）

        $ cpanm Mojo::Weixin
    
    如果安装过程中一直提示下载失败，很可能是因为访问到国外服务器网络比较差
    
    这种情况下可以尝试按如下方式手动指定国内的镜像站点
    
        $ cpanm --mirror http://mirrors.163.com/cpan/ Mojo::Weixin

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
    
    搞定了编译和运行环境之后，再重新回到 步骤2 安装Mojo::Weixin即可
        

###如何使用

1. *我对Perl很熟悉，是一个专业的Perler*

    该项目是一个纯粹的Perl模块，已经发布到了cpan上，请仔细阅读 `Mojo::Weixin` 模块的[使用文档](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod)

    除此之外，你可以看下 [demo](https://github.com/sjdy521/Mojo-Weixin/tree/master/demo) 目录下的更多代码示例

2. *我是对Perl不熟悉，是一个其他语言的开发者，只对提供的消息发送/接收接口感兴趣*

    可以直接把如下代码保存成一个源码文件(必须使用UTF8编码)，使用 perl 解释器来运行
    
        #!/usr/bin/env perl
        use Mojo::Weixin;
        my ($host,$port,$post_api);
        
        $host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
        $port = 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
        #$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行
        
        my $client = Mojo::Weixin->new(log_level=>"info",ua_debug=>0);
        $client->load("ShowMsg");
        $client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
        $client->run();
    
    上述代码保存成 xxxx.pl 文件，然后使用 perl 来运行，就会完成 微信 登录并在本机产生一个监听指定地址端口的 http server
    
        $ perl xxxx.pl
    
    发送好友消息的接口调用示例
    
        http://127.0.0.1:3000/openwx/send_friend_message?id=xxxx&content=hello
        
        * About to connect() to 127.0.0.1 port 3000 (#0)
        *   Trying 127.0.0.1...
        * Connected to 127.0.0.1 (127.0.0.1) port 3000 (#0)
        > GET /openwx/send_friend_message?id=xxxxx&content=hello HTTP/1.1
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
    
    更多接口参数说明参考[Openwx插件API文档](API.md)
    
3.  *我是一个极客，我只想能够在命令行上通过  IRC 的方式来玩转微信聊天*

    请阅读[IRCShell插件使用步骤](IRC.md)
    
###核心依赖模块

* [Mojolicious](https://metacpan.org/pod/Mojolicious)
* [Encode::Locale](https://metacpan.org/pod/Encode::Locale)

###相关文档

* [更新日志](https://github.com/sjdy521/Mojo-Weixin/blob/master/Changes)
* [开发文档](https://metacpan.org/pod/distribution/Mojo-Weixin/doc/Weixin.pod)
* [API](API.md)
* [FAQ](FAQ.md)

###官方交流

* [QQ群](http://jq.qq.com/?_wv=1027&k=kjVJzo)
* [IRC](http://irc.perfi.wang/?channel=#Mojo-Webqq)

###友情链接

*JavaScript*

* [wechaty](https://github.com/zixia/wechaty) Wechaty is wechat for bot in Javascript(ES6). It's a Personal Account Robot Framework/Library.
* [wechatircd](https://github.com/MaskRay/wechatircd) 用IRC客户端控制微信网页版
* [Weixinbot](https://github.com/feit/Weixinbot) Nodejs 封装网页版微信的接口，可编程控制微信消息

*Python*
* [WeixinBot](https://github.com/Urinx/WeixinBot) 网页版微信API，包含终端版微信及微信机器人

###COPYRIGHT 和 LICENCE

Copyright (C) 2014 by sjdy521

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


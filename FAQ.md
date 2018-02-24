#### 1. *打印到终端的日志乱码*

程序默认会自动检测终端的编码，如果你发现乱码，可能是自动检测失败，这种情况下你可以尝试手动设置下输出编码

    $client = Mojo::Weixin->new(log_encoding=>"utf8");
    
#### 2. *如何运行多个微信账号*

使用[Controller-API](Controller-API.md)轻松实现多账号管理

如果你只是希望简单的跑起来一两个帐号，并不想或者不会使用API，可以参考如下方法：

多账号登录主要的问题是需要把每个账号的cookie等数据保存到单独的路径，避免互相影响

在客户端初始化时提供了一个account的参数用于为每个登陆的微信客户端设置单独的标识，这个参数并不是真正的微信账号，可以自由定义

每个账号的代码保存到不同的pl文件中,并设置好account参数
    
##### acb.pl文件

    use Mojo::Weixin;
    my $client = Mojo::Weixin->new(account=>"abc"); 
    $client->load("ShowMsg");
    $client->run();
    
##### def.pl文件

    use Mojo::Weixin;
    my $client = Mojo::Weixin->new(account=>"def"); 
    $client->load("ShowMsg");
    $client->run();
    
单独运行abc.pl和def.pl即可

或者不想搞很多个pl文件，可以只使用一份代码，然后运行时通过环境变量`MOJO_WEIXIN_ACCOUNT`来传递account

    use Mojo::Weixin;
    my $client = Mojo::Weixin->new(); #这里不设置account参数，而是从环境变量获取
    $client->load("ShowMsg");
    $client->run();

#### 3. *如何使用github上最新的代码进行测试*

github上的代码迭代比较频繁，定期打包发布一个稳定版本上传到cpan(Perl官方库)

通过`cpanm Mojo::Weixin`在线下载或更新的都是来自cpan的稳定版本，如果你迫不及待的想要尝试github上的最新代码，

可以手动从github下载最新源码，然后在你的 `xxxx.pl` 文件的开头

通过 `use lib 'github源码解压路径/lib/'` 来指定你要使用该路径下的`Mojo::Weixin`模块

而不是之前通过cpanm安装到系统其他路径上的`Mojo::Weixin`模块，操作步骤演示：

a. 下载最新源码的zip文件 https://github.com/sjdy521/Mojo-Weixin/archive/master.zip

b. 解压master.zip到指定路径，比如Windows C盘根目录 c:/

c. 在你的perl程序开头加上 `use lib 'c:/Mojo-Weixin-master/lib';`

d. 正常执行你的程序即可

```
#!/usr/bin/env perl
use lib 'c:/Mojo-Weixin-master/lib'; #指定加载模块时优先加载的路径
use Mojo::Weixin;
my ($host,$port,$post_api);

$host = "0.0.0.0"; #发送消息接口监听地址，没有特殊需要请不要修改
$port = 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
#$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

my $client = Mojo::Weixin->new(log_level=>"info",http_debug=>0);
$client->load("ShowMsg");
$client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->run();
```

#### 4. 碰到 Can't locate Mojo/Weixin.pm in @INC

说明`Mojo::Weixin`模块没有安装成功，通常是在执行`cpanm Mojo::Weixin`安装的过程中，由于其他依赖模块安装失败导致最终`Mojo::Weixin`没有安装成功

需要逐个检查缺少哪些模块，Linux下你可以直接执行如下命令来检查模块的安装情况,并根据提示进行操作

`curl -ks "https://raw.githubusercontent.com/sjdy521/Mojo-Weixin/master/script/check_dependencies.pl" |perl -`

#### 5. 非root账号安装后无法使用问题

解决方法：

方法1、切换到root账号下重新安装使用

方法2、在非root账号下依次执行如下操作（**不要在任何命令前面加sudo**）

1）安装local::lib模块，执行命令如下：

         cpanm --local-lib=~/perl5 local::lib  && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

2）把相关环境变量写入启动文件中，执行命令如下：

         echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >>~/.bashrc

#### 1. *打印到终端的日志乱码*

程序默认会自动检测终端的编码，如果你发现乱码，可能是自动检测失败，这种情况下你可以尝试手动设置下输出编码

    $client = Mojo::Weixin->new(log_encoding=>"utf8");

#### 2. *如何使用github上最新的代码进行测试*

github上的代码迭代比较频繁，定期打包发布一个稳定版本上传到cpan(Perl官方库)

通过`cpanm Mojo::Weixin`在线下载或更新的都是来自cpan的稳定版本，如果你迫不及待的想要尝试github上的最新代码，

可以手动从github下载最新源码，然后在你的 `xxxx.pl` 文件的开头

通过 `use lib 'github源码解压路径'` 来指定你要使用该路径下的`Mojo::Weixin`模块

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

$host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
$port = 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
#$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

my $client = Mojo::Weixin->new(log_level=>"info",ua_debug=>0);
$client->login();
$client->load("ShowMsg");
$client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api});
$client->run();
```

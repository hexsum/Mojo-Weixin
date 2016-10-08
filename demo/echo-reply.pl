#一个简单的小程序，收到什么消息内容就原样发送什么消息内容给对方
use Mojo::Weixin;
my $client = Mojo::Weixin->new(
    http_debug  => 0,     #是否打印详细的debug信息
    log_level => "info",  #日志打印级别，debug|info|warn|error|fatal
);

#客户端加载ShowMsg插件，用于打印发送和接收的消息到终端
$client->load("ShowMsg");


#ready事件触发时 表示客户端一切准备就绪：已经成功登录、已经加载完个人/好友/群信息等
#你的代码建议尽量写在 ready 事件中
$client->on(ready=>sub{
    my $client = shift;

    #设置接收消息事件的回调函数，在回调函数中对消息以相同内容进行回复
    $client->on(receive_message=>sub{
        my ($client,$msg)=@_;
        $msg->reply($msg->content); #已以相同内容回复接收到的消息
        #你也可以使用$msg->dump() 来打印消息结构
    });

    #你的其他代码写在此处

});

#客户端开始运行
$client->run();

#run相当于执行一个死循环，不会跳出循环之外
#所以run应该总是放在代码最后执行，并且不要在run之后再添加任何自己的代码了

#!/usr/bin/env perl
use Mojo::Weixin;
my ($host,$port,$post_api);
$host = "0.0.0.0"; #发送消息接口监听地址，修改为自己希望监听的地址
$port = $ENV{PORT} || 3000;      #发送消息接口监听端口，修改为自己希望监听的端口
$post_api = $ENV{POST_API};  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行

my $client = Mojo::Weixin->new(
    log_encoding=>  $ENV{LOG_ENCODING} || "utf8",
    log_level   =>  $ENV{LOG_LEVEL} || "info",
    ua_debug    =>  $ENV{UA_DEBUG} || 0,
    http_debug    =>  $ENV{HTTP_DEBUG} || 0,
    (defined $ENV{LOG_PATH}?(log_path =>  $ENV{LOG_PATH}):()),
    (defined $ENV{QRCODE_PATH}?(qrcode_path =>  $ENV{QRCODE_PATH}):()),
);
$client->load("ShowMsg");
$client->load("Openwx",data=>{listen=>[{host=>$host,port=>$port}], post_api=>$post_api,post_event=>1});
$client->load("UploadQRcode");
$client->run();

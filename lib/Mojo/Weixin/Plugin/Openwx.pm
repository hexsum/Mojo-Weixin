package Mojo::Weixin::Plugin::Openwx;
our $PRIORITY = 98;
use strict;
use Encode;
use Mojo::Weixin::Server;
my $server;
sub call{
    my $client = shift;
    my $data   =  shift;
    my $post_api = $data->{post_api} if ref $data eq "HASH";

    if(defined $post_api){
        $client->on(receive_message=>sub{
            my($client,$msg) = @_;
            return if $msg->type !~ /^friend_message|group_message$/;
            $client->http_post($post_api,json=>$msg->to_json_hash,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]接收消息[".$msg->id."]上报成功");
                    if($tx->res->headers->content_type =~m#text/json|application/json#){
                        #文本类的返回结果必须是json字符串
                        my $json;
                        eval{$json = $tx->res->json};
                        if($@){$client->warn($@);return}
                        if(defined $json){
                            #{code=>0,reply=>"回复的消息",format=>"text"}
                            if((!defined $json->{format}) or (defined $json->{format} and $json->{format} eq "text")){
                                $msg->reply(Encode::encode("utf8",$json->{reply})) if defined $json->{reply};
                            }
                        }
                    }
                    #elsif($tx->res->headers->content_type =~ m#image/#){
                    #   #发送图片，暂未实现
                    #}
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]接收消息[".$msg->id."]上报失败: ".$tx->error->{message}); 
                }
            });
        });
    }

    package Mojo::Weixin::Plugin::Openwx::App;
    use Encode;
    use Mojolicious::Lite;
    under sub {
        my $c = shift;
        if(ref $data eq "HASH" and ref $data->{auth} eq "CODE"){
            my $hash  = $c->req->params->to_hash;
            $client->reform_hash($hash);
            my $ret = 0;
            eval{
                $ret = $data->{auth}->($hash,$c);
            };
            $client->warn("插件[Mojo::Weixin::Plugin::Openwx]认证回调执行错误: $@") if $@;
            $c->render(text=>"auth failure",status=>403) if not $ret;
            return $ret;
        }
        else{return 1} 
    };
    get '/openwx/get_user_info'     => sub {$_[0]->render(json=>$client->user->to_json_hash());};
    get '/openwx/get_friend_info'   => sub {$_[0]->render(json=>[map {$_->to_json_hash()} @{$client->friend}]); };
    get '/openwx/get_group_info'    => sub {$_[0]->render(json=>[map {$_->to_json_hash()} @{$client->group}]); };
    any [qw(GET POST)] => '/openwx/send_message'         => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$type,$content)= map {defined $_?encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("type"),$c->param("content"));
        my $object;
        if(defined $type){
            if($type eq "group_message"){
                $object = $client->search_group(id=>$id,displayname=>$displayname); 
            }
            else{
                $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
            }
        }
        elsif(defined $id){
            $object = $client->is_group($id)?$client->search_group(id=>$id,displayname=>$displayname):$client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        }
        else{
            $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        }
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$content,sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->id,code=>$status->code,status=>decode("utf8",$status->msg)});  
                });
                $msg->from("api");
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/send_friend_message'         => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$content)= map {defined $_?encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("content"));
        my $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$content,sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->id,code=>$status->code,status=>decode("utf8",$status->msg)});
                });
                $msg->from("api");
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/send_group_message'         => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$content)= map {defined $_?encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("content"));
        my $object = $client->search_group(id=>$id,displayname=>$displayname);
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$content,sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->id,code=>$status->code,status=>decode("utf8",$status->msg)});
                });
                $msg->from("api");
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}
    }; 
    any '/*whatever'  => sub{whatever=>'',$_[0]->render(text=>"request error",status=>403)};
    package Mojo::Weixin::Plugin::Openwx;
    $server = Mojo::Weixin::Server->new();   
    $server->app($server->build_app("Mojo::Weixin::Plugin::Openwx::App"));
    $server->app->secrets("hello world");
    $server->app->log($client->log);
    if(ref $data eq "ARRAY"){#旧版本兼容性
        $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:5000)} @$data]);
    }
    elsif(ref $data eq "HASH" and ref $data->{listen} eq "ARRAY"){
        $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:5000)} @{ $data->{listen}} ]) ;
    }
    $server->start;
}
1;

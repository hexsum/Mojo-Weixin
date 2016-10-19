package Mojo::Weixin::Plugin::Openwx;
our $PRIORITY = 98;
use strict;
use Encode;
use POSIX qw();
use Mojo::Util qw();
use Mojo::Weixin::Server;
my $server;
sub call{
    my $client = shift;
    my $data   =  shift;
    my $post_api = $data->{post_api} if ref $data eq "HASH";
    $data->{post_media_data} = 1 if not defined $data->{post_media_data};

    if(defined $post_api){
        $client->on(all_event => sub{
            my($client,$event,@args) =@_;
            if($event eq  'login' or $event eq 'stop'){
                my $post_json = {};
                $post_json->{post_type} = "event";
                $post_json->{event} = $event;
                $post_json->{params} = [@args];
                $client->http_post($post_api,json=>$post_json,sub{
                    my($data,$ua,$tx) = @_;
                    if($tx->success){
                        $client->debug("插件[".__PACKAGE__ ."]事件[".$event . "](@args)上报成功");
                    }
                    else{
                        $client->warn("插件[".__PACKAGE__ . "]事件[".$event."](@args)上报失败:" . encode("utf8",$tx->error->{message}));
                    } 
                });
            }
            elsif($event eq 'input_qrcode'){
                my ($qrcode_path,$qrcode_data) = @args;
                eval{ $qrcode_data = Mojo::Util::b64_encode($qrcode_data);};
                if($@){
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: $@");
                    return;
                }
                my $post_json = {};
                $post_json->{post_type} = "event";
                $post_json->{event} = $event;
                $post_json->{params} = [$qrcode_path,$qrcode_data];
                my($data,$ua,$tx) = $client->http_post($post_api,json=>$post_json);
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event . "]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败:" . encode("utf8",$tx->error->{message}));
                }
            }
            elsif($event =~ /^new_group|lose_group|new_friend|lose_friend|new_group_member|lose_group_member$/){
                my $post_json = {};
                $post_json->{post_type} = "event";
                $post_json->{event} = $event;
                if($event =~ /^new_group_member|lose_group_member$/){
                    $post_json->{params} = [$args[0]->to_json_hash(0),$args[1]->to_json_hash(0)];
                }
                else{
                    $post_json->{params} = [$args[0]->to_json_hash(0)];
                }
                $client->http_post($post_api,json=>$post_json,sub{
                    my($data,$ua,$tx) = @_;
                    if($tx->success){
                        $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                    }
                    else{
                        $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".encode("utf8",$tx->error->{message}));
                    }
                });
            }
            elsif($event =~ /^group_property_change|group_member_property_change|friend_property_change|user_property_change$/){
                my ($object,$property,$old,$new) = @args;
                my $post_json = {
                    post_type => "event",
                    event     => $event,
                    params    => [$object->to_json_hash(0),$property,$old,$new],
                };
                $client->http_post($post_api,json=>$post_json,sub{
                    my($data,$ua,$tx) = @_;
                    if($tx->success){
                        $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                    }
                    else{
                        $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".encode("utf8",$tx->error->{message}));
                    }
                });

            }
        }) if $data->{post_event};
        $client->on(receive_message=>sub{
            my($client,$msg) = @_;
            return if $msg->type !~ /^friend_message|group_message|group_notice$/;
            my $post_json = $msg->to_json_hash;
            delete $post_json->{media_data} if ($post_json->{format} eq "media" and ! $data->{post_media_data});
            $post_json->{post_type} = "receive_message";
            $client->http_post($post_api,json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]接收消息[".$msg->id."]上报成功");
                    if($tx->res->headers->content_type =~m#text/json|application/json#){
                        #文本类的返回结果必须是json字符串
                        my $json;
                        eval{$json = $tx->res->json};
                        if($@){$client->warn($@);return}
                        if(defined $json){
                            #暂时先不启用format的属性
                            #{code=>0,reply=>"回复的消息",format=>"text"}
                            #if((!defined $json->{format}) or (defined $json->{format} and $json->{format} eq "text")){
                            #    $msg->reply(Encode::encode("utf8",$json->{reply})) if defined $json->{reply};
                            #}

                            $msg->reply(Encode::encode("utf8",$json->{reply})) if defined $json->{reply};
                            $msg->reply_media(Encode::encode("utf8",$json->{media})) if defined $json->{media} and $json->{media} =~ /^https?:\/\//;
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

        $client->on(send_message=>sub{
            my($client,$msg) = @_;
            return if $msg->type !~ /^friend_message|group_message$/;
            my $post_json = $msg->to_json_hash;
            delete $post_json->{media_data} if ($post_json->{format} eq "media" and ! $data->{post_media_data});
            $post_json->{post_type} = "send_message";
            $client->http_post($post_api,json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]发送消息[".$msg->id."]上报成功");
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
                    $client->warn("插件[".__PACKAGE__ . "]发送消息[".$msg->id."]上报失败: ".$tx->error->{message}); 
                }
            });
        });

    }

    package Mojo::Weixin::Plugin::Openwx::App;
    use Encode;
    use Mojo::IOLoop;
    use Mojolicious::Lite;
    app->hook(after_render=>sub{
        my ($c, $output, $format) = @_;
        my $datatype =  $c->param("datatype");
        return if not defined $datatype;
        return if defined $datatype and $datatype ne 'jsonp';
        my $jsoncallback = $c->param("callback") || 'jsoncallback' . time;
        return if not defined $jsoncallback;
        $$output = "$jsoncallback($$output)";
    });
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
    any [qw(GET POST)] => '/openwx/search_friend' => sub{
        my $c = shift;
        $c->req->params->remove('client');
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_friend(@params);
        if(@objects){
            $c->render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->render(json=>{code=>100,status=>"object not found"});
        }
    };
    any [qw(GET POST)] => '/openwx/search_group' => sub{
        my $c = shift;
        $c->req->params->remove('client');
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_group(@params);
        if(@objects){
            $c->render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->render(json=>{code=>100,status=>"object not found"});
        }
    };
    any [qw(GET POST)] => '/openwx/send_friend_message'         => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$content)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("content"));
        my($media_id,$media_type,$media_mime,$media_name,$media_size,$media_data,$media_mtime,$media_ext,$media_path) = 
            map {defined $_?Encode::encode("utf8",$_):$_} 
        (
            $c->param("media_id"),
            $c->param("media_type"),
            $c->param("media_mime"),
            $c->param("media_name"),
            $c->param("media_size"),
            $c->param("media_data"),
            $c->param("media_mtime"),
            $c->param("media_ext"),
            $c->param("media_path"),
        );
        if(defined $id and $id eq '@all'){#群发给所有好友
            for my $f ($client->friends){
                $client->send_message($f,$content,sub{my $msg= $_[1];$msg->from("api");}) if defined $content;
                if(defined $media_data or defined $media_path){
                    $client->send_media($f,{
                            media_id    =>  $media_id,
                            media_type  =>  $media_type,
                            media_mime  =>  $media_mime,
                            media_name  =>  $media_name,
                            media_size  =>  $media_size,
                            media_data  =>  $media_data,
                            media_mtime =>  $media_mtime,
                            media_ext   =>  $media_ext,
                            media_path  =>  $media_path,
                        },sub{my $msg= $_[1];$msg->from("api");}
                    );
                }
            }
            $c->render(json=>{msg_id=>0,code=>0,status=>'request already executed'});
            return;
        }
        my $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$content,sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    $c->render(json=>{msg_id=>$msg->id,code=>$status->code,status=>Encode::decode("utf8",$status->msg)});
                });
                $msg->from("api");
            }) if defined $content;
            if(defined $media_data or defined $media_path or defined $media_id){
                $client->send_media($object,{
                    media_id    =>  $media_id,
                    media_type  =>  $media_type,
                    media_mime  =>  $media_mime,
                    media_name  =>  $media_name,
                    media_size  =>  $media_size,
                    media_data  =>  $media_data,
                    media_mtime =>  $media_mtime,
                    media_ext   =>  $media_ext,
                    media_path  =>  $media_path,
                },sub{
                    my $msg= $_[1];
                    $msg->cb(sub{
                        my($client,$msg,$status)=@_;
                        $c->render(json=>{msg_id=>$msg->id,media_id=>join(":",$msg->media_id,$msg->media_code),code=>$status->code,status=>Encode::decode("utf8",$status->msg)});
                    });
                    $msg->from("api");
                });
            }
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/send_group_message'         => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$content)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("content"));
        my($media_id,$media_type,$media_mime,$media_name,$media_size,$media_data,$media_mtime,$media_ext,$media_path) =
            map {defined $_?Encode::encode("utf8",$_):$_}
        (
            $c->param("media_id"),
            $c->param("media_type"),
            $c->param("media_mime"),
            $c->param("media_name"),
            $c->param("media_size"),
            $c->param("media_data"),
            $c->param("media_mtime"),
            $c->param("media_ext"),
            $c->param("media_path"),
        );
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
            }) if defined $content;
            if(defined $media_data or defined $media_path or defined $media_id){
                $client->send_media($object,{
                    media_id    =>  $media_id,
                    media_type  =>  $media_type,
                    media_mime  =>  $media_mime,
                    media_name  =>  $media_name,
                    media_size  =>  $media_size,
                    media_data  =>  $media_data,
                    media_mtime =>  $media_mtime,
                    media_ext   =>  $media_ext,
                    media_path  =>  $media_path,
                },sub{
                    my $msg= $_[1];
                    $msg->cb(sub{
                        my($client,$msg,$status)=@_;
                        $c->render(json=>{msg_id=>$msg->id,media_id=>join(":",$msg->media_id,$msg->media_code),code=>$status->code,status=>Encode::decode("utf8",$status->msg)});
                    });
                    $msg->from("api");
                });
            }
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}
    }; 
    any [qw(GET POST)] => '/openwx/consult'         => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$content,$timeout)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("content"),$c->param("timeout"));
        my($media_id,$media_type,$media_mime,$media_name,$media_size,$media_data,$media_mtime,$media_ext,$media_path) =
            map {defined $_?Encode::encode("utf8",$_):$_}
        (
            $c->param("media_id"),
            $c->param("media_type"),
            $c->param("media_mime"),
            $c->param("media_name"),
            $c->param("media_size"),
            $c->param("media_data"),
            $c->param("media_mtime"),
            $c->param("media_ext"),
            $c->param("media_path"),
        );
        my $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$content,sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg,$status)=@_;
                    my ($timer,$cb);
                    $timer = Mojo::IOLoop->timer($timeout || 30,sub{
                        $client->unsubscribe(receive_message=>$cb);
                        $c->render(json=>{msg_id=>$msg->id,code=>$status->code,status=>Encode::decode("utf8",$status->msg),reply_status=>"reply timeout",reply=>undef});
                    });
                    $cb = $client->once(receive_message=>sub{
                        my($client,$msg) = @_;
                        Mojo::IOLoop->remove($timer);
                        $c->render(json=>{reply=>Encode::decode("utf8",$msg->content),msg_id=>$msg->id,code=>$status->code,status=>Encode::decode("utf8",$status->msg)}); 
                    });
                });
                $msg->from("api");
            }) if defined $content;
            if(defined $media_data or defined $media_path or defined $media_id){
                $client->send_media($object,{
                    media_id    =>  $media_id,
                    media_type  =>  $media_type,
                    media_mime  =>  $media_mime,
                    media_name  =>  $media_name,
                    media_size  =>  $media_size,
                    media_data  =>  $media_data,
                    media_mtime =>  $media_mtime,
                    media_ext   =>  $media_ext,
                    media_path  =>  $media_path,
                },sub{
                    my $msg= $_[1];
                    $msg->cb(sub{
                        my($client,$msg,$status)=@_;
                        $c->render(json=>{msg_id=>$msg->id,media_id=>join(":",$msg->media_id,$msg->media_code),code=>$status->code,status=>Encode::decode("utf8",$status->msg)});
                    });
                    $msg->from("api");
                });
            }
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/create_group' => sub{
        my $c = shift;
        my($friends,$displayname)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("friend"),$c->param("displayname"));
        my @id = split /,/,$friends;
        if(@id){
            my @friends;
            for(@id){
                my $friend = $client->search_friend(id=>$_);
                if(not defined $friend){
                    $c->render(json=>{code=>100,status=>"friend id $_ not found"});
                    return;
                }
                push @friends,$friend;
            } 
            my $group = $client->create_group(\@friends,$displayname);
            if(defined $group){
                $c->render(json=>{code=>0,group_id=>$group->id,status=>"success"});
            }
            else{
                $c->render(json=>{code=>201,id=>undef,status=>"failure"});
            }
        }
        else{$c->render(json=>{code=>200,status=>"friend id empty"});}
    };
    any [qw(GET POST)] => '/openwx/invite_friend' => sub{
        my $c = shift;
        my($id,$displayname,$friends)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("displayname"),$c->param("friend"));
        my $object = $client->search_group(id=>$id,displayname=>$displayname,);
        if(not defined $object){
            $c->render(json=>{code=>100,status=>"object not found"});
            return;    
        }
        my @id = split /,/,$friends;
        if(@id){
            my @friends;
            for(@id){
                my $friend = $client->search_friend(id=>$_);
                if(not defined $friend){
                    $c->render(json=>{code=>100,status=>"friend id $_ not found"});
                    return;
                }
                push @friends,$friend;
            }
            if($object->invite_friend(@friends)){
                $c->render(json=>{code=>0,status=>"success"});   
            }
            else{
                $c->render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->render(json=>{code=>200,status=>"friend id empty"});}
        
    };
    any [qw(GET POST)] => '/openwx/kick_group_member' => sub{
        my $c = shift;
        my($id,$displayname,$members)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("displayname"),$c->param("member"));
        my $object = $client->search_group(id=>$id,displayname=>$displayname,);
        if(not defined $object){
            $c->render(json=>{code=>100,status=>"object not found"});
            return;
        }
        my @id = split /,/,$members;
        if(@id){
            my @members;
            for(@id){
                my $member = $object->search_group_member(id=>$_);
                if(not defined $member){
                    $c->render(json=>{code=>100,status=>"member id $_ not found"});
                    return;
                }
                push @members,$member;
            }
            if($object->kick_group_member(@members)){
                $c->render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->render(json=>{code=>200,status=>"member id empty"});}
        
    };
    any [qw(GET POST)] => '/openwx/set_group_displayname' => sub{
        my $c = shift;
        my($id,$displayname,$new_displayname)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("displayname"),$c->param("new_displayname"));
        my $object = $client->search_group(id=>$id,displayname=>$displayname);
        if(defined $object){
            if($object->set_displayname($new_displayname)){
                $c->render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->render(json=>{code=>201,status=>"failure"});
            }
            
        }
        else{$c->render(json=>{code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/set_friend_markname' => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname,$new_markname)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),$c->param("new_markname"));
        my $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        if(defined $object){
            if($object->set_markname($new_markname)){
                $c->render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->render(json=>{code=>100,status=>"object not found"});}

    };
    any [qw(GET POST)] => '/openwx/make_friend' => sub{
        my $c = shift;
        #my($id,$account,$displayname,$markname)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"));
        my($id,$verify)= map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("verify"));
        my $object;
        if($id eq $client->user->id){
            $c->render(json=>{code=>101,status=>"can not be yourself"});
            return;
        }
        if(defined $client->search_friend(id=>$id)){
            $c->render(json=>{code=>101,status=>"already a friend"});
            return;
        }
        for my $group ($client->groups){
            $object = $group->search_group_member(id=>$id,); 
            last if defined $object;
        }
        if(not defined $object){
            $c->render(json=>{code=>100,status=>"object not found"});
            return;
        }

        if($object->make_friend($verify || '')){
            $c->render(json=>{code=>0,status=>"success"});
        }
        else{
            $c->render(json=>{code=>201,status=>"failure"});
        }
    };
    any [qw(GET POST)] => '/openwx/get_avatar' => sub{
        my $c = shift;
        my($id,$account,$displayname,$markname) = map {defined $_?Encode::encode("utf8",$_):$_} ($c->param("id"),$c->param("account"),$c->param("displayname"),$c->param("markname"),);
        my $object =    (defined $id and $id eq $client->user->id) ? $client->user 
                :       $client->is_group($id)? $client->search_group(id=>$id,displayname=>$displayname)
                :       $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname)
        ;
       
        if(defined $object){
            $c->render_later;
            $object->get_avatar(sub{
                my ($path,$data,$mime) = @_;
                my $mtime = time;
                $c->res->headers->cache_control('max-age=3600');
                $c->res->headers->expires(POSIX::strftime("%a, %d %b %Y %H:%M:%S GMT",gmtime($mtime+3600)));
                $c->res->headers->last_modified(POSIX::strftime("%a, %d %b %Y %H:%M:%S GMT",gmtime($mtime)));
                $c->res->headers->content_type($mime || 'image/jpg');
                $c->render(data=>$data,);  
            });
        }
        else{$c->render(json=>{msg_id=>undef,code=>100,status=>"object not found"});}

    };
    any [qw(GET POST)] => '/openwx/get_client_info' => sub{
        my $c = shift;
        $c->render(json=>{
            code=>0,
            pid=>$$,
            account=>$client->account,
            os=>$^O,
            version=>$client->version,
            starttime=>$client->start_time,
            runtime=>int(time - $client->start_time),
            http_debug=>$client->http_debug,
            log_encoding=>$client->log_encoding,
            log_path=>Mojo::Util::decode("utf8",$client->log_path||""),
            log_level=>$client->log_level,
            status=>"success",
        });
    };
    any [qw(GET POST)] => '/openwx/stop_client' => sub{
        my $c = shift;
        $c->render(json=>{
            code=>0,
            account=>$client->account,
            pid=>$$,
            starttime=>$client->start_time,
            runtime=>int(time - $client->start_time),
            status=>"success, client($$) will stop in 3 seconds",
        });
        $client->timer(3=>sub{$client->stop()});#3秒后再执行，让客户端可以收到该api的响应
    };
    any [qw(GET POST)] => '/openwx/upload_media' => sub{
        my $c = shift;
        my($media_type,$media_mime,$media_name,$media_size,$media_data,$media_mtime,$media_ext,$media_path) =
            map {defined $_?Encode::encode("utf8",$_):$_}
        (
            $c->param("media_type"),
            $c->param("media_mime"),
            $c->param("media_name"),
            $c->param("media_size"),
            $c->param("media_data"),
            $c->param("media_mtime"),
            $c->param("media_ext"),
            $c->param("media_path"),
        );
        $c->render_later;
        $client->upload_media({
                media_type  => $media_type,
                media_mime  => $media_mime,
                media_name  => $media_name,
                media_size  => $media_size,
                media_data  => $media_data,
                media_mtime => $media_mtime,
                media_ext   => $media_ext,
                media_path  => $media_path,
            },
            sub{my $json = shift;$client->reform_hash($json,1);$c->render(json=>$json) if defined $c}
        );
        
    };
    any '/*whatever'  => sub{whatever=>'',$_[0]->render(text=>"api not found",status=>403)};
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

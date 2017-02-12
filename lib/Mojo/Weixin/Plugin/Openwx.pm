package Mojo::Weixin::Plugin::Openwx;
our $PRIORITY = 98;
use strict;
use POSIX qw();
use Mojo::Util qw();
use List::Util qw(first);
use Mojo::Weixin::Server;
use Mojo::Weixin::List;
my  $server;
my  $check_event_list;
sub call{
    my $client = shift;
    my $data   =  shift;
    $check_event_list = Mojo::Weixin::List->new(max_size=>$data->{check_event_list_max_size} || 20);
    $data->{post_media_data} = 1 if not defined $data->{post_media_data};
    $data->{post_event} = 1 if not defined $data->{post_event};
    $data->{post_event_list} = [qw(login stop state_change input_qrcode new_group new_friend new_group_member lose_group lose_friend lose_group_member friend_request)] 
        if ref $data->{post_event_list} ne 'ARRAY'; 

    if(defined $data->{poll_api}){
        $client->on('_mojo_weixin_plugin_openwx_poll_over' => sub{
            $client->http_get($data->{poll_api},sub{
                $client->timer($data->{poll_interval} || 5,sub {$client->emit('_mojo_weixin_plugin_openwx_poll_over');});
            });
        });
        $client->emit('_mojo_weixin_plugin_openwx_poll_over');
    }

    $client->on(all_event => sub{
        my($client,$event,@args) =@_;
        return if not first {$event eq $_} @{ $data->{post_event_list} };
        if(defined $data->{post_api} and ($event eq  'login' or $event eq 'stop' or $event eq 'state_change') ){
            my $post_json = {};
            $post_json->{post_type} = "event";
            $post_json->{event} = $event;
            $post_json->{params} = [@args];
            my($data,$ua,$tx) = $client->http_post($data->{post_api},{ua_connect_timeout=>5,ua_request_timeout=>5,ua_inactivity_timeout=>5,ua_retry_times=>1},json=>$post_json);
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]事件[".$event . "](@args)上报成功");
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]事件[".$event."](@args)上报失败:" . $client->encode("utf8",$tx->error->{message}));
            } 
        }
        elsif(defined $data->{post_api} and $event eq 'input_qrcode'){
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
            push @{ $post_json->{params} },$client->qrcode_upload_url if defined $client->qrcode_upload_url;
            my($data,$ua,$tx) = $client->http_post($data->{post_api},json=>$post_json);
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]事件[".$event . "]上报成功");
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败:" . $client->encode("utf8",$tx->error->{message}));
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
            $check_event_list->append($post_json);
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",$tx->error->{message}));
                }
            }) if defined $data->{post_api};
        }
        elsif($event =~ /^group_property_change|group_member_property_change|friend_property_change|user_property_change$/){
            my ($object,$property,$old,$new) = @args;
            my $post_json = {
                post_type => "event",
                event     => $event,
                params    => [$object->to_json_hash(0),$property,$old,$new],
            };
            $check_event_list->append($post_json);
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",$tx->error->{message}));
                }
            }) if defined $data->{post_api};

        }
        elsif($event eq 'friend_request'){
            my($id,$displayname,$verify,$ticket) = @args;
            my $post_json = {
                post_type => "event",
                event     => $event,
                params    => [$id,$displayname,$verify,$ticket],
            };
            $check_event_list->append($post_json);
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",$tx->error->{message}));
                }
            }) if defined $data->{post_api};
        }
        elsif($event =~ /^update_user|update_friend|update_group$/){
            my ($ref) = @args;
            my $post_json = {
                post_type => "event",
                event     => $event,
                params    => [$event eq 'update_user'?$ref->to_json_hash():map {$_->to_json_hash()} @{$ref}], 
            };
            $client->http_post($data->{post_api},json=>$post_json,sub{
                my($data,$ua,$tx) = @_;
                if($tx->success){
                    $client->debug("插件[".__PACKAGE__ ."]事件[".$event."]上报成功");
                }
                else{
                    $client->warn("插件[".__PACKAGE__ . "]事件[".$event."]上报失败: ".$client->encode("utf8",$tx->error->{message}));
                }
            }) if defined $data->{post_api};
        }
    }) if $data->{post_event};
    $client->on(receive_message=>sub{
        my($client,$msg) = @_;
        return if $msg->type !~ /^friend_message|group_message|group_notice$/;
        my $post_json = $msg->to_json_hash;
        delete $post_json->{media_data} if ($post_json->{format} eq "media" and ! $data->{post_media_data});
        $post_json->{post_type} = "receive_message";
        $check_event_list->append($post_json);
        $client->http_post($data->{post_api},json=>$post_json,sub{
            my($data,$ua,$tx) = @_;
            if($tx->success){
                $client->debug("插件[".__PACKAGE__ ."]接收消息[".$msg->id."]上报成功");
                if($tx->res->headers->content_type =~m#text/json|application/json#){
                    #文本类的返回结果必须是json字符串
                    my $json;
                    eval{$json = $client->from_json($tx->res->body)};
                    if($@){$client->warn($@);return}
                    if(defined $json){
                        #暂时先不启用format的属性
                        #{code=>0,reply=>"回复的消息",format=>"text"}
                        #if((!defined $json->{format}) or (defined $json->{format} and $json->{format} eq "text")){
                        #    $msg->reply(Encode::encode("utf8",$json->{reply})) if defined $json->{reply};
                        #}

                        $msg->reply($json->{reply}) if defined $json->{reply};
                        $msg->reply_media($json->{media}) if defined $json->{media} and $json->{media} =~ /^https?:\/\//;
                    }
                }
                #elsif($tx->res->headers->content_type =~ m#image/#){
                #   #发送图片，暂未实现
                #}
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]接收消息[".$msg->id."]上报失败: ". $client->encode("utf8",$tx->error->{message})); 
            }
        }) if defined $data->{post_api};
    });

    $client->on(send_message=>sub{
        my($client,$msg) = @_;
        return if $msg->type !~ /^friend_message|group_message$/;
        my $post_json = $msg->to_json_hash;
        delete $post_json->{media_data} if ($post_json->{format} eq "media" and ! $data->{post_media_data});
        $post_json->{post_type} = "send_message";
        $check_event_list->append($post_json);
        $client->http_post($data->{post_api},json=>$post_json,sub{
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
                            $msg->reply($json->{reply}) if defined $json->{reply};
                        }
                    }
                }
                #elsif($tx->res->headers->content_type =~ m#image/#){
                #   #发送图片，暂未实现
                #}
            }
            else{
                $client->warn("插件[".__PACKAGE__ . "]发送消息[".$msg->id."]上报失败: ".$client->encode("utf8",$tx->error->{message})); 
            }
        }) if defined $data->{post_api};
    });
    package Mojo::Weixin::Plugin::Openwx::App::Controller;
    use Mojo::JSON ();
    use Mojo::Util ();
    use base qw(Mojolicious::Controller);
    sub render{
        my $self = shift;
        if($_[0] eq 'json'){
            $self->res->headers->content_type('application/json');
            $self->SUPER::render(data=>Mojo::JSON::to_json($_[1]),@_[2..$#_]);
        }
        else{$self->SUPER::render(@_)}
    }
    sub safe_render{
        my $self = shift;
        $self->render(@_) if (defined $self->tx and !$self->tx->is_finished);
    }
    sub param{
        my $self = shift;
        my $data = $self->SUPER::param(@_);
        defined $data?Mojo::Util::encode("utf8",$data):undef;
    }
    sub params {
        my $self = shift;
        my $hash = $self->req->params->to_hash ;
        $client->reform($hash);
        return $hash;
    }
    package Mojo::Weixin::Plugin::Openwx::App;
    no utf8;
    use Encode ();
    use Mojo::IOLoop;
    use Mojolicious::Lite;
    app->controller_class('Mojo::Weixin::Plugin::Openwx::App::Controller');
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
            my $hash  = $c->params;
            my $ret = 0;
            eval{
                $ret = $data->{auth}->($hash,$c);
            };
            $client->warn("插件[Mojo::Weixin::Plugin::Openwx]认证回调执行错误: $@") if $@;
            $c->safe_render(json=>{code=>-6,status=>"auth failure"}) if not $ret;
            return $ret;
        }
        else{return 1} 
    };
    get '/openwx/get_user_info'     => sub {$_[0]->safe_render(json=>$client->user->to_json_hash());};
    get '/openwx/get_friend_info'   => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->friend}]); };
    get '/openwx/get_group_info'    => sub {$_[0]->safe_render(json=>[map {$_->to_json_hash()} @{$client->group}]); };
    any [qw(GET POST)] => '/openwx/check_event'          => sub{
        my $c = shift;
        $c->render_later;
        if($check_event_list->size > 0){
            $c->safe_render(json=>scalar($check_event_list->pick_all));
            return;
        }
        else{
            $c->inactivity_timeout(120);
            my($timer,$cb);
            $timer = Mojo::IOLoop->timer( 30 ,sub { $check_event_list->unsubscribe(append=>$cb);$c->safe_render(json=>[]) });
            $cb = $check_event_list->once(append=>sub{
                my($list,$element) = @_;
                Mojo::IOLoop->remove($timer);
                $c->safe_render(json=>[ $list->pick ]);
            });
        }
    };
    any [qw(GET POST)] => '/openwx/search_friend' => sub{
        my $c = shift;
        $c->req->params->remove('client');
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_friend(@params);
        if(@objects){
            $c->safe_render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->safe_render(json=>{code=>100,status=>"object not found"});
        }
    };
    any [qw(GET POST)] => '/openwx/search_group' => sub{
        my $c = shift;
        $c->req->params->remove('client');
        my @params = map {defined $_?Encode::encode("utf8",$_):$_} @{$c->req->params->pairs};
        my @objects = $client->search_group(@params);
        if(@objects){
            $c->safe_render(json=>[map {$_->to_json_hash()} @objects]);
        }
        else{
            $c->safe_render(json=>{code=>100,status=>"object not found"});
        }
    };
    any [qw(GET POST)] => '/openwx/send_friend_message'         => sub{
        my $c = shift;
        my $p = $c->params;
        if(defined $p->{id} and $p->{id} eq '@all'){#群发给所有好友
            $c->render_later;
            for my $f ($client->friends){
                $client->send_message($f,$p->{content},sub{my $msg= $_[1];$msg->from("api");}) if defined $p->{content};
                if(defined $p->{media_data} or defined $p->{media_path}){
                    $c->inactivity_timeout(120);
                    $client->send_media($f,{map {/media_/?($_=>$p->{$_}):()} keys %$p},sub{my $msg= $_[1];$msg->from("api");}
                    );
                }
            }
            $c->safe_render(json=>{id=>0,code=>0,status=>'request already executed'});
            return;
        }
        my $object = $client->search_friend(id=>$p->{id},account=>$p->{account},displayname=>$p->{displayname},markname=>$p->{markname});
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$p->{content},sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg)=@_;
                    $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->info});
                });
                $msg->from("api");
            }) if defined $p->{content};
            if(defined $p->{media_data} or defined $p->{media_path} or defined $p->{media_id}){
                $c->inactivity_timeout(120);
                $client->send_media($object,{map {/media_/?($_=>$p->{$_}):()} keys %$p},sub{
                    my $msg= $_[1];
                    $msg->cb(sub{
                        my($client,$msg)=@_;
                        $c->safe_render(json=>{id=>$msg->id,media_id=>$msg->is_success?$msg->media_id:"",code=>$msg->code,status=>$msg->info});
                    });
                    $msg->from("api");
                });
            }
        }
        else{$c->safe_render(json=>{id=>undef,code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/send_group_message'         => sub{
        my $c = shift;
        my $p = $c->params;
        my $object = $client->search_group(id=>$p->{id},displayname=>$p->{displayname});
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$p->{content},sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg)=@_;
                    $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->info});
                });
                $msg->from("api");
            }) if defined $p->{content};
            if(defined $p->{media_data} or defined $p->{media_path} or defined $p->{media_id}){
                $c->inactivity_timeout(120);
                $client->send_media($object,{map {/media_/?($_=>$p->{$_}):()} keys %$p},sub{
                    my $msg= $_[1];
                    $msg->cb(sub{
                        my($client,$msg)=@_;
                        $c->safe_render(json=>{id=>$msg->id,media_id=>$msg->is_success?$msg->media_id:"",code=>$msg->code,status=>$msg->info});
                    });
                    $msg->from("api");
                });
            }
        }
        else{$c->safe_render(json=>{id=>undef,code=>100,status=>"object not found"});}
    }; 
    any [qw(GET POST)] => '/openwx/consult'         => sub{
        my $c = shift;
        my $p = $c->params;;
        my $object = $client->search_friend(id=>$p->{id},account=>$p->{account},displayname=>$p->{displayname},markname=>$p->{markname});
        if(defined $object){
            $c->render_later;
            $client->send_message($object,$p->{content},sub{
                my $msg= $_[1];
                $msg->cb(sub{
                    my($client,$msg)=@_;
                    my ($timer,$cb);
                    $timer = Mojo::IOLoop->timer($p->{timeout} || 30,sub{
                        $client->unsubscribe(receive_message=>$cb);
                        $c->safe_render(json=>{id=>$msg->id,code=>$msg->code,status=>$msg->info,reply_status=>"reply timeout",reply=>undef});
                    });
                    $cb = $client->once(receive_message=>sub{
                        my($client,$msg) = @_;
                        Mojo::IOLoop->remove($timer);
                        $c->safe_render(json=>{reply=>$msg->content,id=>$msg->id,code=>$msg->code,status=>$msg->info}); 
                    });
                });
                $msg->from("api");
            }) if defined $p->{content};
            if(defined $p->{media_data} or defined $p->{media_path} or defined $p->{media_id}){
                $c->inactivity_timeout(120);
                $client->send_media($object,{map {/media_/?($_=>$p->{$_}):()} keys %$p },sub{
                    my $msg= $_[1];
                    $msg->cb(sub{
                        my($client,$msg)=@_;
                        $c->safe_render(json=>{id=>$msg->id,media_id=>$msg->is_success?$msg->media_id:"",code=>$msg->code,status=>$msg->info});
                    });
                    $msg->from("api");
                });
            }
        }
        else{$c->safe_render(json=>{id=>undef,code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/create_group' => sub{
        my $c = shift;
        my $p = $c->params;
        my($friends,$displayname)= ($p->{friends},$p->{displayname});
        my @id = split /,/,$friends;
        if(@id){
            my @friends;
            for(@id){
                my $friend = $client->search_friend(id=>$_);
                if(not defined $friend){
                    $c->safe_render(json=>{code=>100,status=>"friend id $_ not found"});
                    return;
                }
                push @friends,$friend;
            } 
            my $group = $client->create_group(\@friends,$displayname);
            if(defined $group){
                $c->safe_render(json=>{code=>0,group_id=>$group->id,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,id=>undef,status=>"failure"});
            }
        }
        else{$c->safe_render(json=>{code=>200,status=>"friend id empty"});}
    };
    any [qw(GET POST)] => '/openwx/invite_friend' => sub{
        my $c = shift;
        my $p = $c->params;
        my($id,$displayname,$friends)= @$p{qw(id displayname friends)};
        my $object = $client->search_group(id=>$id,displayname=>$displayname,);
        if(not defined $object){
            $c->safe_render(json=>{code=>100,status=>"object not found"});
            return;    
        }
        my @id = split /,/,$friends;
        if(@id){
            my @friends;
            for(@id){
                my $friend = $client->search_friend(id=>$_);
                if(not defined $friend){
                    $c->safe_render(json=>{code=>100,status=>"friend id $_ not found"});
                    return;
                }
                push @friends,$friend;
            }
            if($object->invite_friend(@friends)){
                $c->safe_render(json=>{code=>0,status=>"success"});   
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->safe_render(json=>{code=>200,status=>"friend id empty"});}
        
    };
    any [qw(GET POST)] => '/openwx/kick_group_member' => sub{
        my $c = shift;
        my $p = $c->params;
        my($id,$displayname,$members)= @$p{qw( id displayname members )};
        my $object = $client->search_group(id=>$id,displayname=>$displayname,);
        if(not defined $object){
            $c->safe_render(json=>{code=>100,status=>"object not found"});
            return;
        }
        my @id = split /,/,$members;
        if(@id){
            my @members;
            for(@id){
                my $member = $object->search_group_member(id=>$_);
                if(not defined $member){
                    $c->safe_render(json=>{code=>100,status=>"member id $_ not found"});
                    return;
                }
                push @members,$member;
            }
            if($object->kick_group_member(@members)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->safe_render(json=>{code=>200,status=>"member id empty"});}
        
    };
    any [qw(GET POST)] => '/openwx/set_group_displayname' => sub{
        my $c = shift;
        my $p = $c->params;
        my($id,$displayname,$new_displayname)= @$p{qw(id displayname new_displayname)};
        my $object = $client->search_group(id=>$id,displayname=>$displayname);
        if(defined $object){
            if($object->set_displayname($new_displayname)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }
            
        }
        else{$c->safe_render(json=>{code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/stick' => sub{
        my $c = shift;
        my($id,$op)= ($c->param("id"),$c->param("op"));
        my $object = $client->is_group_id($id)?$client->search_group(id=>$id,):$client->search_friend(id=>$id);
        if(defined $object){
            if($object->stick($op)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }

        }
        else{$c->safe_render(json=>{code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/set_friend_markname' => sub {
        my $c = shift;
        my $p = $c->params;
        my($id,$markname,$new_markname,$account,$displayname)= @$p{qw( id markname new_markname account displayname)};
        my $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        if(defined $object){
            if($object->set_markname($new_markname)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->safe_render(json=>{code=>100,status=>"object not found"});}
    };
    any [qw(GET POST)] => '/openwx/set_markname' => sub{
        my $c = shift;
        my $p = $c->params;
        my($id,$markname,$new_markname,$group_id,$account,$displayname)= @$p{qw( id markname new_markname group_id account displayname )};
        my $object;
        if(defined $group_id){
            my $group = $client->search_group(id=>$group_id);
            if(not defined $group){
                $c->safe_render(json=>{code=>100,status=>"group not found"});
                return;
            }
            else{
                $object = $group->search_group_member(id=>$id);
            }
        }
        else{
            $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
        }
        if(defined $object){
            if($object->set_markname($new_markname)){
                $c->safe_render(json=>{code=>0,status=>"success"});
            }
            else{
                $c->safe_render(json=>{code=>201,status=>"failure"});
            }
        }
        else{$c->safe_render(json=>{code=>100,status=>"object not found"});}

    };
    any [qw(GET POST)] => '/openwx/make_friend' => sub{
        my $c = shift;
        my($id,$verify)= ($c->param("id"),$c->param("verify"));
        my $object;
        if($id eq $client->user->id){
            $c->safe_render(json=>{code=>101,status=>"can not be yourself"});
            return;
        }
        if(defined $client->search_friend(id=>$id)){
            $c->safe_render(json=>{code=>101,status=>"already a friend"});
            return;
        }
        for my $group ($client->groups){
            $object = $group->search_group_member(id=>$id,); 
            last if defined $object;
        }
        if(not defined $object){
            $c->safe_render(json=>{code=>100,status=>"object not found"});
            return;
        }

        if($object->make_friend($verify || '')){
            $c->safe_render(json=>{code=>0,status=>"success"});
        }
        else{
            $c->safe_render(json=>{code=>201,status=>"failure"});
        }
    };
    any [qw(GET POST)] => '/openwx/get_avatar' => sub{
        my $c = shift;
        my $p = $c->params;
        my($id,$account,$displayname,$markname,$group_id) = @$p{qw( id account displayname markname group_id )};
        my $object =    (defined $id and $id eq $client->user->id) ? $client->user 
                :       $client->is_group_id($id)? $client->search_group(id=>$id,displayname=>$displayname)
                :       undef
        ;
        if(not defined $object){
            if(defined $group_id and defined $id){
                my $group =  $client->search_group(id=>$group_id);
                $object = $group->search_group_member(id=>$id) if defined $group;
            }
            else{
                $object = $client->search_friend(id=>$id,account=>$account,displayname=>$displayname,markname=>$markname);
            }
        }
        if(defined $object){
            $c->render_later;
            my $timer = $client->timer(3,sub{$c->safe_render(data=>'',status=>'503',);});
            $object->get_avatar(sub{
                $client->ioloop->remove($timer);
                my ($path,$data,$mime) = @_;
                my $mtime = time;
                $c->res->headers->cache_control('max-age=3600');
                $c->res->headers->expires(POSIX::strftime("%a, %d %b %Y %H:%M:%S GMT",gmtime($mtime+3600)));
                $c->res->headers->last_modified(POSIX::strftime("%a, %d %b %Y %H:%M:%S GMT",gmtime($mtime)));
                $c->res->headers->content_type($mime || 'image/jpg');
                $c->safe_render(data=>$data,);  
            });
        }
        else{$c->safe_render(json=>{id=>undef,code=>100,status=>"object not found"});}

    };
    any [qw(GET POST)] => '/openwx/accept_friend_request' =>sub{
        my $c = shift;
        my $p = $c->params;
        my($id,$displayname,$ticket) = @$p{qw( id displayname ticket)};
        my $ret = $client->accept_friend_request($id,$displayname,$ticket);
        $c->safe_render(json=>{code=>($ret?0:-1),status=>($ret?"success":"failure"),id=>$id,displayname=>$displayname,ticket=>$ticket});
    };
    any [qw(GET POST)] => '/openwx/get_client_info' => sub{
        my $c = shift;
        $c->safe_render(json=>{
            code=>0,
            pid=>$$,
            account=>$client->account,
            os=>$^O,
            version=>$client->version,
            starttime=>$client->start_time,
            runtime=>int(time - $client->start_time),
            http_debug=>$client->http_debug,
            log_encoding=>$client->log_encoding,
            log_path=>$client->log_path||"",
            log_level=>$client->log_level,
            status=>"success",
        });
    };
    any [qw(GET POST)] => '/openwx/stop_client' => sub{
        my $c = shift;
        $c->safe_render(json=>{
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
        my $p = $c->params;
        $c->render_later;
        $c->inactivity_timeout(120);
        $client->upload_media({map {/media_/?($_=>$p->{$_}):()} keys %$p },
            sub{my $json = shift;$c->safe_render(json=>$json) if defined $c}
        );
        
    };
    any '/*whatever'  => sub{whatever=>'',$_[0]->safe_render(text=>"api not found",status=>403)};
    package Mojo::Weixin::Plugin::Openwx;
    $server = Mojo::Weixin::Server->new();   
    $server->app($server->build_app("Mojo::Weixin::Plugin::Openwx::App"));
    $server->app->secrets("hello world");
    $server->app->log($client->log);
    if(ref $data eq "ARRAY"){#旧版本兼容性
        $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:5000)} @$data]);
    }
    elsif(ref $data eq "HASH" and ref $data->{listen} eq "ARRAY"){
        my @listen;
        for my $listen (@{$data->{listen}}) {
            if($listen->{tls}){
                my $listen_url = 'https://' . ($listen->{host} // "0.0.0.0") . ":" . ($listen->{port}//443);
                my @ssl_option;
                for(keys %$listen){
                    next if ($_ eq 'tls' or $_ eq 'host' or $_ eq 'port');
                    my $key = $_;
                    my $val = $listen->{val};
                    $key=~s/^tls_//g;
                    push @ssl_option,"$_=$listen->{$_}";
                }
                $listen_url .= "?" . join("&",@ssl_option) if @ssl_option;
                push @listen,$listen_url;
            }
            else{
                push @listen,'http://' . ($listen->{host} // "0.0.0.0") . ":" . ($listen->{port}//5000) ;
            }
        }   
        $server->listen(\@listen) ;
    }
    $server->start;
}
1;

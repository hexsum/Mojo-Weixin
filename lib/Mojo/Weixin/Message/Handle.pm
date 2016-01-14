package Mojo::Weixin;
use List::Util qw(first);
use Mojo::Util qw(encode);
use Mojo::Weixin::Message;
use Mojo::Weixin::Const;
use Mojo::Weixin::Message::SendStatus;
use Mojo::Weixin::Message::Queue;
$Mojo::Weixin::Message::LAST_DISPATCH_TIME  = undef;
$Mojo::Weixin::Message::SEND_INTERVAL  = 3;

my @logout_code = qw(1100 1101 1102 1205);
sub send_message{
    my $self = shift;
}
sub gen_message_queue{
    my $self = shift;
    Mojo::Weixin::Message::Queue->new(callback_for_get=>sub{
        my $msg = shift;
        return if $self->is_stop;
        if($msg->class eq "recv"){
            $self->emit(receive_message=>$msg);
        }
        elsif($msg->class eq "send"){
            if($msg->source ne "local"){
                my $status = Mojo::Weixin::Message::SendStatus->new(code=>0,msg=>"发送成功",info=>"来自其他设备");
                if(ref $msg->cb eq 'CODE'){
                    $msg->cb->(
                        $self,
                        $msg,
                        $status,
                    );
                }
                $self->emit(send_message=>
                    $msg,
                    $status,
                );
                return;
            }
            #消息的ttl值减少到0则丢弃消息
            if($msg->ttl <= 0){
                $self->debug("消息[ " . $msg->id.  " ]已被消息队列丢弃，当前TTL: ". $msg->ttl);
                my $status = Mojo::Weixin::Message::SendStatus->new(code=>-5,msg=>"发送失败",info=>"TTL失效");
                if(ref $msg->cb eq 'CODE'){
                    $msg->cb->(
                        $self,
                        $msg,
                        $status,
                    );
                }
                $self->emit(send_message=>
                    $msg,
                    $status,
                );
                return;
            }
            my $ttl = $msg->ttl;
            $msg->ttl(--$ttl);

            my $delay = 0;
            my $now = time;
            if(defined $Mojo::Weixin::Message::LAST_DISPATCH_TIME){
                $delay = $now<$Mojo::Weixin::Message::LAST_DISPATCH_TIME+$Mojo::Weixin::Message::SEND_INTERVAL?
                            $Mojo::Weixin::Message::LAST_DISPATCH_TIME+$Mojo::Weixin::Message::SEND_INTERVAL-$now
                        :   0;
            }
            $self->timer($delay,sub{
                $msg->time(time);
                $self->send_message($msg);
            });
            $Mojo::Weixin::Message::LAST_DISPATCH_TIME = $now+$delay;
        }
    });
}
sub _parse_synccheck_data{
    my $self = shift;
    my($retcode,$selector) = @_;
    if(defined $retcode and defined $selector){
        if($retcode == 0 and $selector != 0){
            $self->_synccheck_error_count(0);
            $self->_sync();
        }
        elsif($retcode == 0 and $selector = 0){
            $self->_synccheck_error_count(0);
            $self->_synccheck();
        }
        elsif(first {$retcode == $_} @logout_code){
            $self->logout($retcode);
            $self->stop();
        }
        elsif($self->_synccheck_error_count < 3){
            my $c = $self->_synccheck_error_count; 
            $self->_synccheck_error_count(++$c);
            $self->timer(5,sub{$self->_sync();});
        }
    }
    else{
        $self->timer(2,sub{$self->_synccheck();});
    }
    
}
sub _parse_sync_data {
    my $self = shift;
    my $json = shift;
    if(not defined $json){
        $self->_synccheck();
        return;
    }
    if(first {$json->{BaseResponse}{Ret} == $_} @logout_code  ){
        $self->logout($d->{BaseResponse}{Ret});
        $self->stop();
    }

    elsif($json->{BaseResponse}{Ret} !=0){
        $self->warn("收到无法识别消息，已将其忽略");
        return;
    }
    $self->sync_key($json->{SyncKey}) if $json->{SyncKey}{Count}!=0;
    $self->skey($json->{SKey}) if $json->{SKey};


    #群组或联系人变更
    if($json->{ModContactCount}!=0){
        for my $e (@{$json->{ModContactList}}){
            if($self->is_group($e->{UserName})){#群组
                my $group = {member=>[]};
                for(keys %KEY_MAP_GROUP){
                    $group->{$_} = defined $e->{$KEY_MAP_GROUP{$_}}?encode("utf8",$e->{$KEY_MAP_GROUP{$_}}):"";
                }
                if($e->{MemberCount} != 0){
                    for my $m (@{$e->{MemberList}}){
                        my $member = {};
                        for(keys %KEY_MAP_GROUP_MEMBER){
                            $member->{$_} = defined $m->{$KEY_MAP_GROUP_MEMBER{$_}}?encode("utf8", $m->{$KEY_MAP_GROUP_MEMBER{$_}}):"";
                        }
                        push @{ $group->{member} }, $member;
                    }
                }
                my $g = $self->search_group(id=>$group->{id});
                if(not defined $g){#新增群组
                    $self->add_group(Mojo::Weixin::Group->new($group));
                }
                else{#更新已有联系人
                    $g->update($group);
                }
            }
            else{#联系人
                my $friend = {};
                for(keys %KEY_MAP_FRIEND){
                    $friend->{$_} = encode("utf8",$e->{$KEY_MAP_FRIEND{$_}});
                }
                my $f = $self->search_friend(id=>$friend->{id});
                if(not defined $f){$self->add_friend(Mojo::Weixin::Friend->new($friend))}
                else{$f->update($friend)}
            }
        }
    }

    if($json->{ModChatRoomMemberCount}!=0){
        
    }

    if($json->{DelContactCount}!=0){
        for my $e (@{$json->{DelContactList}}){
            if($self->is_group($e->{UserName})){
                my $g = $self->search_group(id=>$e->{UserName});
                $self->remove_group($g) if defined $g;
            }
            else{
                my $f = $self->search_friend(id=>$e->{UserName});
                $self->remove_friend($f) if defined $f;
            }
        }
    }

    #有新消息
    if($json->{AddMsgCount} != 0){
        for my $e (@{$json->{AddMsgList}}){
            if($e->{MsgType} == 1){
                my $msg = {};
                $msg->{format} = "text";
                for(keys %KEY_MAP_MESSAGE){$msg->{$_} = defined $e->{$KEY_MAP_MESSAGE{$_}}?encode("utf8",$e->{$KEY_MAP_MESSAGE{$_}}):"";}
                eval{
                    require HTML::Entities;
                    $msg->{content} = HTML::Entities::decode_entities($msg->{content});
                };
                if($e->{FromUserName} eq $self->user->id){#发送的消息
                    $msg->{source} = 'outer';
                    $msg->{class} = "send";
                    $msg->{sender_id} = $self->user->id;
                    if($self->is_group($e->{ToUserName})){
                        $msg->{type} = "group_message";
                        $msg->{group_id} = $e->{ToUserName};
                    }
                    else{
                        $msg->{type} = "friend_message";
                        $msg->{receiver_id} = $e->{ToUserName};
                    }
                }
                elsif($e->{ToUserName} eq $self->user->id){#接收的消息
                    $msg->{class} = "recv";
                    $msg->{receiver_id} = $self->user->id;
                    if($self->is_group($e->{FromUserName})){#接收到群组消息
                        $msg->{type} = "group_message";
                        $msg->{group_id} = $e->{FromUserName};
                        my ($member_id,$content) = $msg->{content}=~/^(\@.+):<br\/>(.*)/g;
                        if(defined $member_id and defined $content){
                                $msg->{sender_id} = $member_id;
                                $msg->{content} = $content;
                        }
                    }
                    else{
                        $msg->{type} = "friend_message";
                        $msg->{sender_id} = $e->{FromUserName};
                    }
                }

                $self->message_queue->put(Mojo::Weixin::Message->new($msg)); 
            }#MsgType == 1 END
        }
    }

    if($json->{ContinueFlag}!=0){
        $self->_sync();
    }
    else{
        $self->_synccheck();
    }
}

1;

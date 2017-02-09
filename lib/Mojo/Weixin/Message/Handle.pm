package Mojo::Weixin;
use strict;
use Mojo::Weixin::Const qw(%KEY_MAP_USER %KEY_MAP_GROUP %KEY_MAP_GROUP_MEMBER %KEY_MAP_FRIEND %KEY_MAP_MEDIA_CODE);
use List::Util qw(first);
use Mojo::Weixin::Message;
use Mojo::Weixin::Const;
use Mojo::Weixin::Message;
use Mojo::Weixin::Message::Queue;
use Mojo::Weixin::Message::Remote::_upload_media;
use Mojo::Weixin::Message::Remote::_get_media;
use Mojo::Weixin::Message::Remote::_send_media_message;
use Mojo::Weixin::Message::Remote::_send_text_message;
$Mojo::Weixin::Message::LAST_DISPATCH_TIME  = undef;
$Mojo::Weixin::Message::SEND_INTERVAL  = 3;

sub gen_message_queue{
    my $self = shift;
    Mojo::Weixin::Message::Queue->new(callback_for_get=>sub{
        my $msg = shift;
        return if $self->is_stop;
        if($msg->class eq "recv"){
            if($msg->format eq "media"){
                if($self->download_media){
                    $self->_get_media($msg,sub{
                        my ($path,$data,$msg) = @_;
                        if($msg->media_size == 0 and $msg->media_type eq 'emoticon'){
                            $msg->content("[表情](获取数据为空，可能需要手机查看)");
                        }
                        else{
                            $msg->content( $msg->content. "(". $msg->media_path . ")");
                        }
                        $self->emit(receive_media=>$path,$data,$msg);
                        $self->emit(receive_message=>$msg);
                    });
                }
                else{
                    $self->emit(receive_message=>$msg);
                }
            }
            else{ $self->emit(receive_message=>$msg);}
        }
        elsif($msg->class eq "send"){
            if($msg->source ne "local"){
                $msg->send_status(code=>0,msg=>"发送成功",info=>"来自其他设备");
                if($msg->format eq "media"){
                    if($self->download_media){
                        $self->_get_media($msg,sub{
                            my ($path,$data,$msg) = @_;
                            if($msg->media_size == 0 and $msg->media_type eq 'emoticon'){
                                $msg->content("[表情](获取数据为空，可能需要手机查看)");
                            }
                            else{
                                $msg->content( $msg->content. "(". $msg->media_path . ")");
                            }
                            $msg->cb->($self,$msg) if ref $msg->cb eq 'CODE';
                            $self->emit(send_media=>$path,$data,$msg);
                            $self->emit(send_message=>$msg);
                        });
                    }
                    else{
                        $msg->cb->($self,$msg) if ref $msg->cb eq 'CODE';
                        $self->emit(send_message=>$msg);
                    }
                }
                else{ 
                    $msg->cb->($self,$msg) if ref $msg->cb eq 'CODE';
                    $self->emit(send_message=>$msg);
                }
                return;
            }
            #消息的ttl值减少到0则丢弃消息
            if($msg->ttl <= 0){
                $self->debug("消息[ " . $msg->id.  " ]已被消息队列丢弃，当前TTL: ". $msg->ttl);
                $msg->send_status(code=>-5,msg=>"发送失败",info=>"TTL失效");
                if(ref $msg->cb eq 'CODE'){
                    $msg->cb->(
                        $self,
                        $msg,
                    );
                }
                $self->emit(send_message=>
                    $msg,
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
                if($msg->format eq "text"){
                    $self->_send_text_message($msg);
                }
                elsif($msg->format eq "media"){
                    $self->_send_media_message($msg);
                }
            });
            $Mojo::Weixin::Message::LAST_DISPATCH_TIME = $now+$delay;
        }
    });
}
sub _parse_synccheck_data{
    my @logout_code = qw(1100 1101 1102 1205);
    my $self = shift;
    my($retcode,$selector) = @_;
    if(defined $retcode and defined $selector){
        if($retcode == 0 and $selector != 0){
            $self->_synccheck_error_count(0);
            $self->_sync();
        }
        elsif($retcode == 0 and $selector == 0){
            $self->_synccheck_error_count(0);
        }
        elsif($retcode == 1101 and $self->stop_with_mobile){
            $self->stop();
        }
        elsif(first {$retcode == $_} @logout_code){
            $self->relogin($retcode);
            return;
        }
        elsif($self->_synccheck_error_count <= 10){
            my $c = $self->_synccheck_error_count; 
            $self->_synccheck_error_count(++$c);
        }
        else{
            $self->relogin();
            return;
        }
    }
}
sub _parse_sync_data {
    my $self = shift;
    my $json = shift;
    return if not defined $json;
    my @logout_code = qw(1100 1102 1205);
    if($json->{BaseResponse}{Ret} == 1101){#手机端强制下线 或 其他设备登录Web微信
        $self->info("收到下线通知");
        $self->logout($json->{BaseResponse}{Ret});
        $self->stop();
    }
    elsif(first {$json->{BaseResponse}{Ret} == $_} @logout_code  ){
        $self->relogin($json->{BaseResponse}{Ret});
        return;
    }
    elsif($json->{BaseResponse}{Ret} !=0){
        $self->warn("收到无法识别消息，已将其忽略");
        return;
    }
    $self->sync_key($json->{SyncKey}) if $json->{SyncKey}{Count}!=0;
    $self->synccheck_key($json->{SyncCheckKey}) if $json->{SyncCheckKey}{Count}!=0;
    $self->skey($json->{SKey}) if $json->{SKey};


    #群组或联系人变更
    if($json->{ModContactCount}!=0){
        for my $e (@{$json->{ModContactList}}){
            if($self->is_group_id($e->{UserName})){#群组
                my $group = {member=>[]};
                for(keys %KEY_MAP_GROUP){
                    $group->{$_} = $e->{$KEY_MAP_GROUP{$_}} // "";
                }
                if($e->{MemberCount} != 0){
                    for my $m (@{$e->{MemberList}}){
                        my $member = {};
                        for(keys %KEY_MAP_GROUP_MEMBER){
                            $member->{$_} = $m->{$KEY_MAP_GROUP_MEMBER{$_}} // "";
                        }
                        push @{ $group->{member} }, $member;
                    }
                }
                my $g = $self->search_group(id=>$group->{id});
                if(not defined $g){#新增群组
                    if(not $self->update_group($group->{id},1)){
                        $self->add_group(Mojo::Weixin::Group->new($group));
                    }
                }
                else{#更新已有联系人
                    $g->update($group);
                }
            }
            else{#联系人
                my $friend = {};
                for(keys %KEY_MAP_FRIEND){
                    $friend->{$_} = $e->{$KEY_MAP_FRIEND{$_}} if defined $e->{$KEY_MAP_FRIEND{$_}};
                }
                my $f = $self->search_friend(id=>$friend->{id});
                if(not defined $f){
                    $self->add_friend(Mojo::Weixin::Friend->new($friend));
                }
                else{$f->update($friend)}
            }
        }
    }

    if($json->{ModChatRoomMemberCount}!=0){
        
    }

    if($json->{DelContactCount}!=0){
        for my $e (@{$json->{DelContactList}}){
            if($self->is_group_id($e->{UserName})){
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
            my $msg = {};
            for(keys %KEY_MAP_MESSAGE){
                $msg->{$_} = $e->{$KEY_MAP_MESSAGE{$_}} // "";
            }
            if($e->{MsgType} == 1){#好友消息或群消息
                $msg->{format} = "text";
            }
            elsif($e->{MsgType} == 3){#图片消息
                $msg->{format} = "media";
                $msg->{media_type} = "image";
                $msg->{media_code} = $e->{MsgType};
                $msg->{media_id} = $msg->{id} . ":" . $msg->{media_code};
            }
            elsif($e->{MsgType} == 47){#表情或gif图片
                $msg->{format} = "media";
                $msg->{media_type} = "emoticon";
                $msg->{media_code} = $e->{MsgType};
                $msg->{media_id} = $msg->{id} . ":" . $msg->{media_code};
            }
            elsif($e->{MsgType} == 62){#小视频
                $msg->{format} = "media";
                $msg->{media_type} = "microvideo";
                $msg->{media_code} = $e->{MsgType};
                $msg->{media_id} = $msg->{id} . ":" . $msg->{media_code};
            }
            elsif($e->{MsgType} == 43){#视频
                $msg->{format} = "media";
                $msg->{media_type} = "video";
                $msg->{media_code} = $e->{MsgType};
                $msg->{media_id} = $msg->{id} . ":" . $msg->{media_code};
            }
            elsif($e->{MsgType} == 34){#语音
                $msg->{format} = "media";
                $msg->{media_type} = "voice";
                $msg->{media_code} = $e->{MsgType};
                $msg->{media_id} = $msg->{id} . ":" . $msg->{media_code};
            }
            elsif($e->{MsgType} == 37){#好友推荐消息
                $msg->{format} = "text";
                #$msg->{class} = "recv";
                #$msg->{type} = "friend_message";
                #$msg->{receiver_id} = $self->user->id;
                #$msg->{sender_id} = $e->{FromUserName};
                my $id = $e->{RecommendInfo}{UserName};
                my $displayname = $e->{RecommendInfo}{NickName};
                my $verify = $e->{RecommendInfo}{Content};
                my $ticket = $e->{RecommendInfo}{Ticket};
                #$msg->data({id=>$id,verify=>$verify,ticket=>$ticket,displayname=>$displayname});
                #$msg->{content} = "收到[ " . $displayname  . " ]好友验证请求：" . ($verify?$verify:"(验证内容为空)");
                $self->_webwxstatusnotify($e->{FromUserName},1);
                $self->emit("friend_request",$id,$displayname,$verify,$ticket);
                next;
            }
            elsif($e->{MsgType} == 10000){#群提示消息
                $msg->{format} = "text";
            }
            elsif($e->{MsgType} == 10002){#撤回消息
                $msg->{format} = "revoke";
            }
            elsif($e->{MsgType} == 49) {#应用分享
                $msg->{format} = "app";
                $msg->{app_title} = $e->{FileName};
                $msg->{app_url}   = $e->{Url};
            }
            elsif($e->{MsgType} == 42){#名片消息
                $msg->{format} = "card";
                $msg->{card_name} = $e->{RecommendInfo}{NickName};
                $msg->{card_id} = $e->{RecommendInfo}{UserName};
                $msg->{card_province} = $e->{RecommendInfo}{Province};
                $msg->{card_city} = $e->{RecommendInfo}{City};
                $msg->{card_account} = $e->{RecommendInfo}{Alias};
                $msg->{card_sex} = $self->code2sex($e->{RecommendInfo}{Sex});
                #$msg->{card_avatar} = '';
            }
            elsif($e->{MsgType} == 51){#会话、联系人信息同步
                if($msg->{StatusNotifyCode} == 4 or $msg->{StatusNotifyCode} == 2){#联系人、群组信息需要同步
                    my @id = split /,/,$msg->{StatusNotifyUserName};
                    my @group_ids;
                    my @friend_ids;
                    for (@id){
                        next if $_ eq $self->user->id;
                        if($self->is_group_id($_)){push @group_ids,$_ if not $self->search_group(id=>$_);}
                        else{push @friend_ids,$_ if not $self->search_friend(id=>$_);}
                    } 
                    $self->update_group(@group_ids) if @group_ids;
                    $self->update_friend(@friend_ids) if @friend_ids;
                }
                next;
            }
            else{next;}
            if($e->{FromUserName} eq $self->user->id){#发送的消息
                $msg->{source} = 'outer';
                $msg->{class} = "send";
                $msg->{sender_id} = $self->user->id;
                if($self->is_group_id($e->{ToUserName})){
                    $msg->{type} = "group_message";
                    $msg->{group_id} = $e->{ToUserName};
                }
                else{
                    $msg->{type} = "friend_message";
                    $msg->{receiver_id} = $e->{ToUserName};
                }
            }
            #elsif($e->{ToUserName} eq $self->user->id){#接收的消息
            else{#接收的消息
                $msg->{class} = "recv";
                $msg->{receiver_id} = $self->user->id;
                $msg->{type} = "group_message";
                if($self->is_group_id($e->{FromUserName})){#接收到群组消息
                    $msg->{group_id} = $e->{FromUserName};
                    if($e->{MsgType} == 10000){#群提示信息
                        $msg->{type} = "group_notice";
                    }
                    elsif( $msg->{content}=~/^(\@.+):<br\/>(.*)$/s ){
                        my ($member_id,$content) = ($1,$2);
                        if(defined $member_id and defined $content){
                                $msg->{sender_id} = $member_id;
                                $msg->{content} = $content;
                        }
                    }
                }
                else{#接收到的好友消息
                    $msg->{type} = "friend_message";
                    $msg->{sender_id} = $e->{FromUserName};
                }
            }
            if($msg->{format} eq "media"){
                $msg->{content} = '[图片]' if $msg->{media_type} eq "image";
                $msg->{content} = '[语音]' if $msg->{media_type} eq "voice";
                $msg->{content} = '[视频]' if $msg->{media_type} eq "video";
                $msg->{content} = '[小视频]' if $msg->{media_type} eq "microvideo";
                $msg->{content} = '[表情]' if $msg->{media_type} eq "emoticon";
            }
            elsif(defined $msg->{content}){
                eval{$msg->{content} = Mojo::Util::html_unescape($msg->{content});};
                $self->warn("html entities unescape fail: $@") if $@;
            }
            if($msg->{format} eq "app"){
                eval{
                    $msg->{content}=~s/<br\/>/\n/g;
                    require Mojo::DOM;
                    my $dom = Mojo::DOM->new($msg->{content});
                    if( $dom->at('msg > appmsg > type')->content != 5){
                        $msg->{content} = "[应用分享]标题：$msg->{app_title}\n[应用分享]链接：$msg->{app_url}"; 
                        return;
                    }
                    $msg->{app_id} = $dom->at('msg > appmsg')->attr->{appid};
                    $msg->{app_title} = $dom->at('msg > appmsg > title')->content;
                    $msg->{app_name} = $dom->at('msg > appinfo > appname')->content;
                    $msg->{app_url} = $dom->at('msg > appmsg > url')->content;
                    $msg->{app_desc} = $dom->at('msg > appmsg > des')->content;
                    for( ($msg->{app_title},$msg->{app_desc},$msg->{app_url},$msg->{app_name}) ){
                        s/<!\[CDATA\[(.*?)\]\]>/$1/g;
                    }
                    $msg->{app_url} = Mojo::Util::html_unescape($msg->{app_url});
                    $msg->{content} = "[应用分享]标题：@{[$msg->{app_title} || '未知']}\n[应用分享]描述：@{[$msg->{app_desc} || '未知']}\n[应用分享]应用：@{[$msg->{app_name} || '未知']}\n[应用分享]链接：@{[$msg->{app_url} || '未知']}";
                };
                if($@){
                    $self->warn("app message xml parse fail: $@") if $@;
                    $msg->{content} = "[应用分享]标题：$msg->{app_title}\n[应用分享]链接：$msg->{app_url}";
                }
            }
            elsif($msg->{format} eq "revoke"){
                #<sysmsg type=\"revokemsg\"><revokemsg><session>wxid_8mn2bmkx40so22</session><oldmsgid>1072643834</oldmsgid><msgid>4835386562261263795</msgid><replacemsg><![CDATA[你撤回了一条消息]]></replacemsg></revokemsg></sysmsg>
                eval{
                    require Mojo::DOM;
                    my $dom = Mojo::DOM->new($msg->{content});
                    return if  $dom->at('sysmsg')->attr->{type} ne 'revokemsg';
                    #$msg->{revoke_session} = $dom->at('sysmsg > revokemsg > session')->content;
                    $msg->{revoke_id} = $dom->at('sysmsg > revokemsg > msgid')->content;
                    $msg->{content} = $dom->at('sysmsg > revokemsg > replacemsg')->content;
                    $msg->{content}=~s/<!\[CDATA\[(.*?)\]\]>/$1/g;

                    #纠正自己撤回消息时，消息类型错乱的问题
                    if($msg->{content} eq '你撤回了一条消息' and $msg->{class} eq 'recv'){
                        $msg->{class} = 'send';
                        $msg->{source} = 'outer';
                        if($msg->{type} eq "group_message"){
                            $msg->{sender_id} = $msg->{receiver_id};
                            delete $msg->{receiver_id};
                        }
                        elsif($msg->{type} eq "friend_message"){
                            ($msg->{sender_id},$msg->{receiver_id}) = ($msg->{receiver_id},$msg->{sender_id});
                        }
                    }
                    $msg->{content} = "[撤回消息](" . $msg->{content} . ")";
                };
                if($@){
                    $self->warn("app message xml parse fail: $@") if $@;
                    $msg->{content} = "[撤回消息]";
                }
            }
            elsif($msg->{format} eq "card"){
                #<msg bigheadimgurl="http://wx.qlogo.cn/mmhead/ver_1/k99g2RHrEeib9KMhGmXZGSIGDjgnmiaX2acT2wl04so2ibsq8ysVPRkRRNQyRLmUVptBpcHt6lvUZym5JgOSd4fug/0" smallheadimgurl="http://wx.qlogo.cn/mmhead/ver_1/k99g2RHrEeib9KMhGmXZGSIGDjgnmiaX2acT2wl04so2ibsq8ysVPRkRRNQyRLmUVptBpcHt6lvUZym5JgOSd4fug/132" username="xxx" nickname="xxx"  shortpy="" alias="" imagestatus="3" scene="17" province="xxx" city="xxx" sign="" sex="1" certflag="0" certinfo="" brandIconUrl="" brandHomeUrl="" brandSubscriptConfigUrl="" brandFlags="0" regionCode="CN_Shanghai_Pudong New District" />
                $msg->{content}=~s/<br\/>/\n/g;
                eval{
                    require Mojo::DOM;
                    my $dom = Mojo::DOM->new($msg->{content});
                    $msg->{card_avatar} = $dom->at('msg')->attr->{bigheadimgurl};
                    $msg->{card_name} = $dom->at('msg')->attr->{nickname};
                    $msg->{card_account} = $dom->at('msg')->attr->{alias};
                    $msg->{card_province} = $dom->at('msg')->attr->{province};
                    $msg->{card_city} = $dom->at('msg')->attr->{city};
                    $msg->{card_sex} = $self->code2sex($dom->at('msg')->attr->{sex});
                };
                $self->warn("app message xml parse fail: $@") if $@;
                $msg->{content} = "[名片]昵称：@{[$msg->{card_name} || '未知']}\n[名片]性别：@{[$msg->{card_sex} || '未知']}\n[名片]位置：@{[$msg->{card_province} || '未知']} @{[$msg->{card_city} || '未知']}\n[名片]头像：@{[$msg->{card_avatar} || '未知']}";
            }
            $self->message_queue->put(Mojo::Weixin::Message->new($msg)); 
        }
    }

    if($json->{ContinueFlag}!=0){
        $self->_sync();
        return;
    }
}

sub send_message{
    my $self = shift;
    my $object = shift;
    my $content = shift;
    my $callback = shift;
    if( ref($object) ne "Mojo::Weixin::Friend" and ref($object) ne "Mojo::Weixin::Group") { 
        $self->error("无效的发送消息对象");
        return;
    }
    my $msg = Mojo::Weixin::Message->new(
        id => $self->now(),
        content => $content,
        sender_id => $self->user->id,
        receiver_id => (ref $object eq "Mojo::Weixin::Friend"?$object->id : undef),
        group_id =>(ref $object eq "Mojo::Weixin::Group"?$object->id : undef),
        type => (ref $object eq "Mojo::Weixin::Group"?"group_message":"friend_message"),
        class => "send",
        format => "text", 
        from  => "code",
    );

    $callback->($self,$msg) if ref $callback eq "CODE";
    $self->emit(before_send_message=>$msg);
    $self->message_queue->put($msg);

}
my %KEY_MAP_MEDIA_TYPE = reverse %KEY_MAP_MEDIA_CODE;
sub send_media {
    my $self = shift;
    my $object = shift;
    my $media = shift;
    my $callback = shift;
    if( ref($object) ne "Mojo::Weixin::Friend" and ref($object) ne "Mojo::Weixin::Group") {
        $self->error("无效的发送消息对象");
        return;
    }
    my $media_info = {};
    if(ref $media eq ""){
        $media_info->{media_path} = $media;
    }
    elsif(ref $media eq "HASH"){
        $media_info = $media;
        if(defined $media_info->{media_id}){#定义了media_id意味着不会上传文件，忽略media_path
            my ($id,$code) = split(/:/,$media_info->{media_id},2);
            $media_info->{media_id} = $id if $id;
            $media_info->{media_code} = $code if $code;
            if(!defined $media_info->{media_code} and defined $media_info->{media_type}){
               $media_info->{media_code} = $KEY_MAP_MEDIA_CODE{$media_info->{media_type}} // 6; 
            }
            elsif(!defined $media_info->{media_code}){
                $media_info->{media_code} = 6;
            }
        }
        if(defined $media_info->{media_code} and !defined $media_info->{media_type}){
            $media_info->{media_type} = $KEY_MAP_MEDIA_TYPE{$media_info->{media_code}} || 'file';
        }

    }

    my $media_type =    $media_info->{media_type} eq "image"     ?  "[图片]"
                    :   $media_info->{media_type} eq "emoticon"  ?  "[表情]"
                    :   $media_info->{media_type} eq "video"     ?  "[视频]"
                    :   $media_info->{media_type} eq "microvideo"?  "[小视频]"
                    :   $media_info->{media_type} eq "voicce"    ?  "[语音]"
                    :   $media_info->{media_type} eq "file"      ?  "[文件]"
                    :   "[文件]"
    ;
    
    my $msg = Mojo::Weixin::Message->new(
        id => $self->now(),
        media_id   => $media_info->{media_id},
        media_name => $media_info->{media_name},
        media_type => $media_info->{media_type},
        media_code => $media_info->{media_code},
        media_path => $media_info->{media_path},
        media_data => $media_info->{media_data},
        media_mime => $media_info->{media_mime},
        media_size => $media_info->{media_size},
        media_mtime => $media_info->{media_mtime},
        media_ext => $media_info->{media_ext},
        content => "$media_type(" . ($media_info->{media_path} || $media_info->{media_id}) . ")",
        sender_id => $self->user->id,
        receiver_id => (ref $object eq "Mojo::Weixin::Friend"?$object->id : undef),
        group_id =>(ref $object eq "Mojo::Weixin::Group"?$object->id : undef),
        type => (ref $object eq "Mojo::Weixin::Group"?"group_message":"friend_message"),
        class => "send",
        format => "media",
    );

    $callback->($self,$msg) if ref $callback eq "CODE";
    $self->message_queue->put($msg);
}

sub upload_media {
    my $self = shift;
    my $opt = shift;
    my $callback = pop;
    my $msg = Mojo::Weixin::Message->new(%$opt);
    $self->_upload_media($msg,sub{
        my($msg,$json) = @_;
        $callback->({
            media_id    => $msg->media_id,
            media_code  => $msg->media_code,
            media_type  => $msg->media_type,
            media_path  => $msg->media_path,
            media_name  => $msg->media_name,
            media_size  => $msg->media_size,
            media_mime  => $msg->media_mime,
            media_mtime => $msg->media_mtime,
            media_ext   => $msg->media_ext,
        }) if ref $callback eq "CODE";
    });
}
sub reply_message{
    my $self = shift;
    my $msg = shift;
    my $content = shift;
    my $callback = shift;
    if($msg->class eq "recv"){
        if($msg->type eq "group_message"){
            $self->send_message($msg->group,$content,$callback);
        }
        elsif($msg->type eq "friend_message"){
            $self->send_message($msg->sender,$content,$callback);
        }
    }
    elsif($msg->class eq "send"){
        if($msg->type eq "group_message"){
            $self->send_message($msg->group,$content,$callback);
        }
        elsif($msg->type eq "friend_message"){
            $self->send_message($msg->receiver,$content,$callback);
        }

    }
}

sub reply_media_message {
    my $self = shift;
    my $msg = shift;
    my $media = shift;
    my $callback = shift; 
    if($msg->class eq "recv"){
        if($msg->type eq "group_message"){
            $self->send_media($msg->group,$media,$callback);
        }
        elsif($msg->type eq "friend_message"){
            $self->send_media($msg->sender,$media,$callback);
        }
    }
    elsif($msg->class eq "send"){
        if($msg->type eq "group_message"){
            $self->send_media($msg->group,$media,$callback);
        }
        elsif($msg->type eq "friend_message"){
            $self->send_media($msg->receiver,$callback);
        }

    }
}


1;

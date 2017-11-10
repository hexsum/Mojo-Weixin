sub Mojo::Weixin::_send_text_message {
    my $self = shift;
    my $msg = shift;
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxsendmsg";
    my @query_string =();
    push @query_string,(pass_ticket     => $self->url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $r = sprintf "%.3f", rand();
    $r=~s/\.//g;
    my $t = $self->now() . $r; 
	#开放client_msgid	Modified By Cntlis
	my $_clientmsgid;
	if ($msg->local_msgid and $msg->local_msgid ne ""){
		$_clientmsgid= $msg->local_msgid;
	}else{
		$_clientmsgid= $t;
	}
	
	#可以发送特殊内容，譬如名片 Modified By Cntlis
	my $msgtype= 1;
	my $msgcontent= $msg->content;
	if ($msgcontent =~ /<MsgType>(\d+)<MsgType>/){
		#这里是匹配到
		$msgcontent= "$'";
		$msgtype= "$1";
		
		$self->debug("匹配到的MsgType是:$1\n");
		$self->debug("匹配到的内容是:$'\n");
	}
	
    my $post = {
        BaseRequest =>  {
            DeviceID    => $self->deviceid,
            Sid         => $self->wxsid,
            Skey        => $self->skey,
            Uin         => $self->wxuin, 
        },
        Msg             => {
            ClientMsgId     =>  $_clientmsgid,
            Content         =>  $msgcontent,
            FromUserName    =>  $msg->sender_id,
            LocalID         =>  $_clientmsgid,
            ToUserName      =>  ($msg->type eq "group_message"?$msg->group_id:$msg->receiver_id),
            Type            =>  $msgtype,
        },
    };     
    my $callback = sub {
        my $json = shift;
        $msg->_parse_send_status_data($json);
        if(!$msg->is_success and $msg->ttl > 0){
            #$self->debug("消息[ " . $msg->id . " ]发送失败，尝试重新发送，当前TTL: " . $msg->ttl);
            #$self->message_queue->put($msg);
			#为了避免重复发送消息，已经增加了ClientMsgId，故这里的重新发送屏蔽	Modified By Cntlis
			$self->debug("消息[ " . $msg->id . " ]疑似发送失败，停止发送，当前TTL: " . $msg->ttl);
            return;
        }
        else{
            if(ref $msg->cb eq 'CODE'){
                $msg->cb->(
                    $self,
                    $msg,
                );
            }

            $self->emit(send_message => $msg);
        }
    };
    #Mojo::JSON::to_json will escape the slash charactor '/' into '\/' 
    #Weixin Server doesn't supported this feature
    #So we do some dirty work there to disable this feature
    $post->{Msg}{Content} =~ s#/#__SLASH__#g;
    my $json = $self->to_json($post);
    $json =~ s#__SLASH__#/#g;
    # dirty work done

    $self->http_post($self->gen_url($api,@query_string),{json=>1,'Content-Type'=>'application/json'},$json,$callback);
}
1;

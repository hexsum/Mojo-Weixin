use Mojo::Util qw(url_escape decode);
sub Mojo::Weixin::_send_text_message {
    my $self = shift;
    my $msg = shift;
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxsendmsg";
    my @query_string =();
    push @query_string,(pass_ticket     => url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $r = sprintf "%.3f", rand();
    $r=~s/\.//g;
    my $t = $self->now() . $r; 
    my $post = {
        BaseRequest =>  {
            DeviceID    => $self->deviceid,
            Sid         => $self->wxsid,
            Skey        => $self->skey,
            Uin         => $self->wxuin, 
        },
        Msg             => {
            ClientMsgId     =>  $t,
            Content         =>  decode("utf8",$msg->content),
            FromUserName    =>  $msg->sender_id,
            LocalID         =>  $t,
            ToUserName      =>  ($msg->type eq "group_message"?$msg->group_id:$msg->receiver_id),
            Type            =>  1,
        },
    };     
    my $callback = sub {
        my $json = shift;
        my $status = $self->_parse_send_status_data($json);
        if(defined $status and !$status->is_success and $msg->ttl > 0){
            $self->debug("消息[ " . $msg->id . " ]发送失败，尝试重新发送，当前TTL: " . $msg->ttl);
            $self->message_queue->put($msg);
            return;
        }
        elsif(defined $status){
            if(ref $msg->cb eq 'CODE'){
                $msg->cb->(
                    $self,
                    $msg,
                    $status,
                );
            }

            $self->emit(send_message => $msg,$status);
        }
    };
    #Mojo::JSON::encode_json will escape the slash charactor '/' into '\/' 
    #Weixin Server doesn't supported this feature
    #So we do some dirty work there to disable this feature
    $post->{Msg}{Content} =~ s#/#__SLASH__#g;
    my $json = $self->encode_json($post);
    $json =~ s#__SLASH__#/#g;
    # dirty work done

    $self->http_post($self->gen_url($api,@query_string),{json=>1,'Content-Type'=>'application/json'},$json,$callback);
}
1;

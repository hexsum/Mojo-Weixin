use strict;
use Mojo::Util ();
sub Mojo::Weixin::_send_media_message {
    my $self = shift;
    my $msg = shift; 
    if($msg->format ne "media" or !defined $msg->media_path){
        $self->error("无效的 media msg");
        return;
    }
    my $callback = sub{
        my $json = shift;
        my $status = $self->_parse_send_status_data($json);
        if(defined $status and !$status->is_success and $msg->ttl > 0){
            $self->debug("消息[ " . $msg->id . " ]发送失败，尝试重新发送，当前TTL: " . $msg->ttl);
            $self->message_queue->put($msg);
            return;
        }
        elsif(defined $status){
            if(ref $msg->cb eq 'CODE'){
                $msg->cb->($self, $msg,$status,);
            }
            $self->emit(send_message => $msg,$status);
        }
    };
    $self->steps(
        sub{
            my $delay = shift;
            $self->_upload_media($msg,$delay->begin(0,));
        },
        sub{
            my($delay,$upload_json,$msg) = @_;
            if(not defined $upload_json or $upload_json->{Ret}!=0 or !$upload_json->{MediaId}){
                $self->warn("media [ ".$msg->media_path . " ] upload failure");
                my $status = Mojo::Weixin::Message::SendStatus->new(code=>-1,msg=>"发送失败",info=>"media上传失败");
                if(ref $msg->cb eq 'CODE'){
                    $msg->cb->($self, $msg,$status,);
                }
                $self->emit(send_message => $msg,$status);
                return;
            }
            $msg->media_id($upload_json->{MediaId}) if not defined $msg->media_id;
            my $api;
            my @query_string = (
                fun => 'async',
                f   => 'json',
                $self->pass_ticket?(pass_ticket => Mojo::Util::url_escape($self->pass_ticket)):()
            );
            my $post;
            my $t = sub{my $r = sprintf "%.3f", rand();$r=~s/\.//g;return $self->now() . $r;}->();
            if($msg->media_mime=~/^image/){
                $api = 'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxsendmsgimg';
                $post = {
                    BaseRequest =>  {
                        DeviceID    => $self->deviceid,
                        Sid         => $self->wxsid,
                        Skey        => $self->skey,
                        Uin         => $self->wxuin, 
                    },
                    Msg             => {
                        ClientMsgId     =>  $t,
                        FromUserName    =>  $msg->sender_id,
                        MediaId         =>  $msg->media_id,
                        LocalID         =>  $t,
                        ToUserName      =>  ($msg->type eq "group_message"?$msg->group_id:$msg->receiver_id),
                        Type            =>  3,
                    },
                };
            }
            else{
                $api = 'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxsendappmsg';
                my $content = 
                "<appmsg appid='wxeb7ec651dd0aefa9' sdkver=''>" .
                    "<title>" . $msg->media_name . "</title>"   .
                    "<des></des>"  .
                    "<action></action>" . 
                    "<type>6</type>" . 
                    "<content></content>" .
                    "<url></url>" .
                    "<lowurl></lowurl>" .
                    "<appattach>" .
                        "<totallen>" . $msg->media_size . "</totallen>" .
                        "<attachid>" . $msg->media_id . "</attachid>" .
                        "<fileext>"  . $msg->media_ext  ."</fileext>" .
                    "</appattach>" .
                    "<extinfo></extinfo>" . 
                "</appmsg>";
                $post = {
                    BaseRequest =>  {
                        DeviceID    => $self->deviceid,
                        Sid         => $self->wxsid,
                        Skey        => $self->skey,
                        Uin         => $self->wxuin, 
                    },
                    Msg             => {
                        ClientMsgId     =>  $t,
                        FromUserName    =>  $msg->sender_id,
                        Content         =>  $content,
                        LocalID         =>  $t,
                        ToUserName      =>  ($msg->type eq "group_message"?$msg->group_id:$msg->receiver_id),
                        Type            =>  6,
                    },
                };     
            }
            $post->{Msg}{Content} =~ s#/#__SLASH__#g if exists $post->{Msg}{Content};
            my $json = $self->encode_json($post);
            $json =~ s#__SLASH__#/#g;
            $self->http_post(
                $self->gen_url($api,@query_string),
                {json=>1,Referer=>'https://' . $self->domain . '/','Content-Type'=>'application/json'},
                $json,
                $callback
            );
        },
    );
}
1;

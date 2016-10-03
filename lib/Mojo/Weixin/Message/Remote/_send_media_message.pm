use strict;
use Mojo::Util ();
use Mojo::Weixin::Const ();
sub Mojo::Weixin::_send_media_message {
    my $self = shift;
    my $msg = shift; 
    if($msg->format ne "media" or (!defined $msg->media_path and !defined $msg->media_id) ){
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
            $self->emit(send_media => $msg->media_path,$msg->media_data,$msg);
            $self->emit(send_message => $msg,$status);
        }
    };
    $self->steps(
        sub{
            my $delay = shift;
            defined $msg->media_id ? $delay->begin(0)->($msg): $self->_upload_media($msg,$delay->begin(0,));
        },
        sub{
            my($delay,$msg) = @_;
            if(not defined $msg->media_id){
                my $status = Mojo::Weixin::Message::SendStatus->new(code=>-1,msg=>"发送失败",info=>"media_id无效");
                if(ref $msg->cb eq 'CODE'){
                    $msg->cb->($self, $msg,$status,);
                }
                $self->emit(send_message => $msg,$status);
                return;
            }
            my $api;
            my @query_string = (
                fun => 'async',
                f   => 'json',
                $self->pass_ticket?(pass_ticket => Mojo::Util::url_escape($self->pass_ticket)):()
            );
            my $t = sub{my $r = sprintf "%.3f", rand();$r=~s/\.//g;return $self->now() . $r;}->();
            my $post = {
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
                    #Type            =>  $Mojo::Weixin::Const::KEY_MAP_MEDIA_CODE{$msg->media_type} || 6,
                    Type            =>  $msg->media_code || $Mojo::Weixin::Const::KEY_MAP_MEDIA_CODE{$msg->media_type} || 6,
                },
                Scene           => 0,
            };
            if($msg->media_type eq "image"){
                $api =  'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxsendmsgimg';
            }
            elsif($msg->media_type eq "video" or $msg->media_type eq "microvideo"){
                $api =  'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxsendvideomsg';
            }
            #elsif($msg->media_type eq "voice"){
            # 
            #}
            elsif($msg->media_type eq "emoticon"){
                $api =  'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxsendemoticon';
                @query_string = (
                    fun=>'sys',
                    $self->pass_ticket?(pass_ticket => Mojo::Util::url_escape($self->pass_ticket)):()    
                );
                $post->{Msg}{EmojiFlag} = 2;
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
                $post->{Msg}{Content} = $content;
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

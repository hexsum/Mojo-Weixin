use Mojo::Util qw(url_escape);
sub Mojo::Weixin::_sync {
    my $self = shift;
    return if ($self->_synccheck_running or $self->_sync_running);
    $self->_sync_running(1);
    my $api = 'https://'. $self->domain . '/cgi-bin/mmwebwx-bin/webwxsync';
    my @query_string = (
        sid     => $self->wxsid,
    );
    push @query_string,(skey => $self->skey) if $self->skey;
    push @query_string,(pass_ticket    => url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {Uin => $self->wxuin,Sid=>$self->wxsid,},
        SyncKey     =>  $self->sync_key,
        rr          =>  $self->now(),
    };
    my $callback = sub{
        my ($json,$ua,$tx) = @_;
        $self->emit(receive_raw_message=>$tx->res->body,$json);
        $self->_sync_running(0);
        if(defined $json and $json->{BaseResponse}{Ret} == -1){#对于 -1 的消息做延迟处理，防止刷屏
            $self->timer(5,sub{
                $self->emit("sync_over",$json);
            }); 
        }
        else{
            $self->emit("sync_over",$json);
        }
    };
    $self->http_post($self->gen_url($api,@query_string),{Referer=>'https://' . $self->domain .  '/',json=>1},json=>$post,$callback);
}
1;

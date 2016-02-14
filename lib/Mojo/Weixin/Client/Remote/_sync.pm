use Mojo::Util qw(url_escape);
sub Mojo::Weixin::_sync {
    my $self = shift;
    return if ($self->_synccheck_running or $self->_sync_running);
    $self->_sync_running(1);
    my $api = 'https://'. $self->domain . '/cgi-bin/mmwebwx-bin/webwxsync';
    my @query_string = (
        sid     => $self->wxsid,
        skey    => url_escape($self->skey),
        pass_ticket => $self->pass_ticket,
    );
    my $post = {
        BaseRequest =>  {Uin => $self->wxuin,Sid=>$self->wxsid,},
        SyncKey     =>  $self->sync_key,
        rr          =>  $self->now(),
    };
    my $callback = sub{
        my ($json,$ua,$tx) = @_;
        $self->emit(receive_raw_message=>$tx->res->body,$json);
        $self->_sync_running(0);
        $self->emit("sync_over",$json);
    };
    $self->http_post($self->gen_url($api,@query_string),{json=>1},json=>$post,$callback);
}
1;

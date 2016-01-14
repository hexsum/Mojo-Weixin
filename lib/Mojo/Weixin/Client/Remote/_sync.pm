use Mojo::Util qw(url_escape);
sub Mojo::Weixin::_sync {
    my $self = shift;
    my $api = 'https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxsync';
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
        my $json = shift;
        $self->_parse_sync_data($json);
    };
    $self->timer(1,sub{
        $self->http_post($self->gen_url($api,@query_string),{json=>1},json=>$post,$callback);
    });
}
1;

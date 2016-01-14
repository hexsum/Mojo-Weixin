sub Mojo::Weixin::_synccheck{
    my $self = shift;
    my $api = "https://webpush.weixin.qq.com/cgi-bin/mmwebwx-bin/synccheck";
    my $callback = sub {
        my $data = shift;
        #window.synccheck={retcode:"0",selector:"0"}
        my($retcode,$selector) = $data=~/window\.synccheck={retcode:"([^"]+)",selector:"([^"]+)"}/g;
        $self->_parse_synccheck_data($retcode,$selector);
    };
    my @query_string = (
        skey        =>  $self->skey,
        callback    =>  "jQuery1830847224326338619_" . $self->now(),
        r           =>  $self->now(),
        sid         =>  $self->wxsid,
        uin         =>  $self->wxuin,
        deviceid    =>  $self->deviceid,
        synckey     =>  join("|",map {$_->{Key} . "_" . $_->{Val};} @{$self->sync_key->{List}}),
        _           =>  $self->now(),
    );
    $self->timer(1,sub{
        $self->http_get($self->gen_url2($api,@query_string),$callback);
    });
}
1;

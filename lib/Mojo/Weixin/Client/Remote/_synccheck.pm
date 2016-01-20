sub Mojo::Weixin::_synccheck{
    my $self = shift;
    return if($self->_sync_running or $self->_synccheck_running);
    $self->_synccheck_running(1);
    my $api = "https://webpush.weixin.qq.com/cgi-bin/mmwebwx-bin/synccheck";
    my $callback = sub {
        my $data = shift;
        #window.synccheck={retcode:"0",selector:"0"}
        my($retcode,$selector) = $data=~/window\.synccheck={retcode:"([^"]+)",selector:"([^"]+)"}/g;
        $self->_synccheck_running(0);
        $self->emit("synccheck_over",$retcode,$selector); 
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
    $self->http_get($self->gen_url2($api,@query_string),$callback);
}
1;

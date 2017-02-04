sub Mojo::Weixin::_synccheck{
    my $self = shift;
    if($self->_sync_running or $self->_synccheck_running){
        #$self->_synccheck_running(0);
        $self->emit("synccheck_over",undef,undef,1);
        $self->debug("消息处理程序进行中，避免重复运行(1)");
        return;
    }
    $self->debug("检查消息...");
    $self->_synccheck_running(1);
    my $api = "https://webpush.". $self->domain . "/cgi-bin/mmwebwx-bin/synccheck";
    my $callback = sub {
        my $data = shift;
        #window.synccheck={retcode:"0",selector:"0"}
        $self->_synccheck_running(0);
        if(defined $data){
            my($retcode,$selector) = $data=~/window\.synccheck=\{retcode:"([^"]+)",selector:"([^"]+)"\}/g;
            $self->emit("synccheck_over",$retcode,$selector,1); 
        }
        else{
            $self->emit("synccheck_over",undef,undef,0);
        }
    };
    my @query_string = (
        r           =>  $self->now(),
        skey        =>  $self->skey,
        sid         =>  $self->wxsid,
        uin         =>  $self->wxuin,
        deviceid    =>  $self->deviceid,
        synckey     =>  join("|",map {$_->{Key} . "_" . $_->{Val};} @{$self->synccheck_key->{List}}),
        _           =>  $self->now(),
    );
    my $id = $self->http_get($self->gen_url2($api,@query_string),{Referer=>"https://" .$self->domain . "/"},$callback);
    $self->_synccheck_connection_id($id);
}
1;

sub Mojo::Weixin::_sync {
    my $self = shift;
    #if($self->_synccheck_running or $self->_sync_running){
    #if($self->_sync_running){
    #    $self->debug("消息处理程序进行中，避免重复运行(2)");
    #    return;
    #}
    $self->debug("接收消息...");
    $self->_sync_running(1);
    my $api = 'https://'. $self->domain . '/cgi-bin/mmwebwx-bin/webwxsync';
    my @query_string = (
        sid     => $self->wxsid,
    );
    push @query_string,(skey => $self->skey) if $self->skey;
    push @query_string,(pass_ticket    => $self->url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {Uin => $self->wxuin,Sid=>$self->wxsid,},
        SyncKey     =>  $self->sync_key,
        rr          =>  $self->now(),
    };
    my $callback = sub{
        my ($json,$ua,$tx) = @_;
        my $status  = 1;
        if(not defined $json){$status = 0;}
        elsif(defined $json and $json->{BaseResponse}{Ret} == -1){$status = 0}
        $self->_sync_running(0);
        $self->emit(receive_raw_message=>$tx->res->body,$json);
        $self->emit("sync_over",$json,$status);
    };
    $self->http_post($self->gen_url($api,@query_string),{Referer=>'https://' . $self->domain .  '/',json=>1},json=>$post,$callback);
}
1;

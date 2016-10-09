sub Mojo::Weixin::_get_qrcode_uuid {
    my $self = shift;
    my $api = 'https://login.'. $self->domain .  '/jslogin';
    my @query_string = (
        appid           =>  'wx782c26e4c19acffb',
        redirect_uri    =>  'https://'.$self->domain . '/cgi-bin/mmwebwx-bin/webwxnewloginpage',
        fun             =>  'new',
        lang            =>  $self->lang || 'zh_CN',
        _               =>  $self->now(),
    );
    my $data = $self->http_get($self->gen_url2($api,@query_string));
    return if not defined $data;
    $data=~s/\s+//g;
    my($code,$uuid) = $data=~/window\.QRLogin\.code=(\d+);window\.QRLogin\.uuid="([^"]+)"/g;
    return ($code==200 and $uuid)?$uuid: undef;
}
1;

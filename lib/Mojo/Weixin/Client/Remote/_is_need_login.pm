sub Mojo::Weixin::_is_need_login {
    my $self = shift;
    my $api = "https://". $self->domain ."/";
    return 1 if $self->login_state eq "relogin";
    $self->debug("检查登录Cookie是否有效...");
    my $data = $self->http_get($api,{ua_debug_res_body=>0});
    my $ret = $data=~/window\.MMCgi\s*=\s*{\s*isLogin\s*:\s*(!!"1")\s*}/s?0:1;
    if(not $ret){
        $self->debug("登录cookie仍然有效，可以免扫码登录");
    }
    else{
        $self->debug("登录cookie不存在或已失效，需要扫码登录");
    }
    return $ret;
}
1;

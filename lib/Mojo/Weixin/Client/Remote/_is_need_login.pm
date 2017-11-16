sub Mojo::Weixin::_is_need_login {
    my $self = shift;
    my $api = "https://". $self->domain ."/";
    return 1 if $self->login_state eq "relogin";
	$self->info("检测Cookie是否失效，访问".$api."\n");
    my $data = $self->http_get($api,{ua_debug_res_body=>0});
    return $data=~/window\.MMCgi\s*=\s*{\s*isLogin\s*:\s*(!!"1")\s*}/s?0:1;
}
1;

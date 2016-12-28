sub Mojo::Weixin::_logout {
    my $self = shift;
    my $type = shift || 0;
    my $api = "https://". $self->domain ."/cgi-bin/mmwebwx-bin/webwxlogout";
    my @query_string = (
        redirect    =>  1,
        type        =>  $type,
        skey        =>  $self->url_escape($self->skey),
    );
    my $post = {
        sid => $self->wxsid,
        uin => $self->wxuin,
    };
    $self->http_post($self->gen_url($api,@query_string),{ua_debug_res_body=>0,Referer=>"https://". $self->domain . "/"},form=>$post,);
}
1;

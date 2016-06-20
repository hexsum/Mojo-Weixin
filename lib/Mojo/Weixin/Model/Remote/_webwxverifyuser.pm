sub Mojo::Weixin::_webwxverifyuser {
    my $self = shift;
    my $member = shift;
    my $content = shift;
    my $api = 'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxverifyuser';
    my @query_string = (
        r => $self->now(),
    );
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
        Opcode => 2,
        VerifyUserListSize => 1,
        VerifyUserList=>[{
            Value => $member->id,
            VerifyUserTicket => "",
        }],
        VerifyContent => $content || "",
        SceneListCount => 1,
        SceneList => [33],
        skey => $self->skey,
    };

    my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post);
    return if not defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    return 1;
}

1;

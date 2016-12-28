sub Mojo::Weixin::_webwxverifyuser {
    my $self = shift;
    my $id = shift;
    my $content = shift;
    my $opcode = shift;
    my $ticket = shift;

    $content = "" if not defined $content;
    $opcode = 2 if not defined $opcode;
    $ticket = "" if not defined $ticket;

    my $api = 'https://' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxverifyuser';
    my @query_string = (
        r => $self->now(),
    ); 
    push @query_string,(pass_ticket=>$self->url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
        Opcode => $opcode,
        VerifyUserListSize => 1,
        VerifyUserList=>[{
            Value => $id,
            VerifyUserTicket => $ticket,
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

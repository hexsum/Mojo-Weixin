use strict;
sub Mojo::Weixin::_revoke_message {
    my $self = shift;
    my ($msg_id,$receiver_id) = @_;
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxrevokemsg";
    my @query_string =();
    push @query_string,(pass_ticket     => $self->url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {
            DeviceID    => $self->deviceid,
            Sid         => $self->wxsid,
            Skey        => $self->skey,
            Uin         => $self->wxuin, 
        },
        ClientMsgId     => sub{my $r = sprintf "%.3f", rand();$r=~s/\.//g;my $t = $self->now() . $r;$t;}->(),
        SvrMsgId        => $msg_id,
        ToUserName      => $receiver_id,
    };

    my $json = $self->http_post($self->gen_url($api,@query_string),{blocking=>1,Referer=>'https://' . $self->domain .  '/',json=>1},json=>$post);
    return if not defined $json;
    return if $json->{BaseResponse}{Ret} !=0;
    return 1;
}

1;

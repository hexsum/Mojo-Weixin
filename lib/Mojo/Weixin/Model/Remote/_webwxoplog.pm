use Mojo::Util qw(decode url_escape);
sub Mojo::Weixin::_webwxoplog {
    my $self = shift;
    my $friend_id = shift;
    my $markname = shift;
    my $api = 'https://' .$self->domain . '/cgi-bin/mmwebwx-bin/webwxoplog';
    my @query_string = (
        pass_ticket => url_escape($self->pass_ticket),
    );
    #push @query_string,(pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
        CmdId => 2,
        RemarkName => decode("utf8",$markname),
        UserName   => $friend_id,
    };

    my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post); 
    return if not defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    return 1;
}
1;


use strict;
use Mojo::Util qw(url_escape);
sub Mojo::Weixin::_webwxstatusnotify {
    my $self = shift;
    $self->info("发送状态通知...");
    my $code = shift || 3;
    my $api = "https://". $self->domain . "/cgi-bin/mmwebwx-bin/webwxstatusnotify";
    my @query_string = (pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
        ClientMsgId     => sub{my $r = sprintf "%.3f", rand();$r=~s/\.//g;return $self->now() . $r;}->(),
        Code            => $code,
        FromUserName    => $self->user->id,
        ToUserName      => $self->user->id,
    };

    my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post);
    if(not defined $json or (defined $json and $json->{BaseResponse}{Ret}!=0)){
        $self->error("发送状态通知失败");
        return;
    }
    return 1;
}
1;

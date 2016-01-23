use Mojo::Util qw(url_escape);
my %type = qw(
    1100    0
    1101    1
    1102    1
    1205    1
);
sub Mojo::Weixin::_logout {
    my $self = shift;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxlogout";
    my $retcode = shift;
    my $type = exists $type{$retcode}?$type{$retcode}:0;
    my @query_string = (
        redirect    =>  1,
        type        =>  $type,
        skey        =>  url_escape($self->skey),
    );
    my $post = {
        sid => $self->wxsid,
        uin => $self->wxuin,
    };
    $self->info("客户端正在注销...");
    $self->http_post($self->gen_url($api,@query_string),{Referer=>"https://wx.qq.com/?&lang=zh_CN"},form=>$post,);
}
1;

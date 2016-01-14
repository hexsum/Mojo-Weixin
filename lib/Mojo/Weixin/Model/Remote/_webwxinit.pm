use Mojo::Util qw(encode url_escape);
use Mojo::Weixin::Const;
sub Mojo::Weixin::_webwxinit{
    my $self = shift;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxinit";
    my @query_string = (
        r           =>  $self->now(),
        lang        =>  'zh_CN',
    );
    push @query_string,(pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
    };
    
    my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://wx.qq.com/?&lang=zh_CN'},json=>$post);
    return if not defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    $self->sync_key($json->{SyncKey}) if $json->{SyncKey}{Count} !=0;
    $self->skey($json->{Skey}) if $json->{Skey};
    my $user = {};
    for(keys %KEY_MAP_USER){
        $user->{$_} = defined $json->{User}{$KEY_MAP_USER{$_}}?encode("utf8",$json->{User}{$KEY_MAP_USER{$_}} ) : "";
    }

    my @friend_id;
    my @group_id;
    for my $e (@{ $json->{ContactList} }){
        if($self->is_group($e->{UserName})){
            push @group_id,$e->{UserName}; 
        }
        else{
            push @friend_id,$e->{UserName};
        }
    }

    return [$user,\@friend_id,\@group_id];
}
1

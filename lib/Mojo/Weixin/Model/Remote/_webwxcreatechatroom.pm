use strict;
use Mojo::Util qw(url_escape decode);
use Mojo::Weixin::Const;
use Mojo::Weixin::Group;
sub Mojo::Weixin::_webwxcreatechatroom {
    my $self = shift;
    my $friends = shift;
    my $chatroom_displayname = shift;

    if(ref $friends ne "ARRAY" or 0+@$friends<1){
        $self->error("_webwxcreatechatroom invaild friend list");
        return;
    }

    my $api = 'https://' .$self->domain . '/cgi-bin/mmwebwx-bin/webwxcreatechatroom';
    my @query_string = (
        r => $self->now(),
    );
    push @query_string,(pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
            DeviceID    =>  $self->deviceid,
        },
        MemberCount     =>  0+@$friends,
        MemberList      =>  [map { +{UserName=>$_->id} } @$friends],
        Topic           =>  (defined $chatroom_displayname?decode("utf8",$chatroom_displayname):""),
    };
    
    my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post);
    return if not defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    my $group = {id=>$json->{ChatRoomName},name=>$json->{Topic},member=>[]};
    for my $m (@{ $json->{MemberList} }){
        my $member = {};
        for(keys %Mojo::Weixin::Const::KEY_MAP_GROUP_MEMBER){
            $member->{$_} = defined $m->{$KEY_MAP_GROUP_MEMBER{$_}}?encode("utf8", $m->{$KEY_MAP_GROUP_MEMBER{$_}} ):"";
        }
        $member->{sex} = $self->code2sex($member->{sex});
        push @{$group->{member}},$member;
    }
    return $group; 
}
1;

use Mojo::Util qw(encode url_escape);
use strict;
use Mojo::Weixin::Const qw(%KEY_MAP_USER %KEY_MAP_GROUP %KEY_MAP_GROUP_MEMBER %KEY_MAP_FRIEND);
sub Mojo::Weixin::_webwxbatchgetcontact{
    my $self  = shift;
    my @id = @_;
    my $post = {
        BaseRequest =>  {
            Uin         =>  $self->wxuin,
            DeviceID    =>  $self->deviceid,
            Sid         =>  $self->wxsid,
            Skey        =>  $self->skey,
        },
        Count       =>  @id+0,
        List        =>  [ map { {UserName=>$_,ChatRoomId=>""} } @id ],
    };
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxbatchgetcontact";
    my @query_string = (
        type        =>  "ex",
        r           =>  $self->now(),
    );
    push @query_string,(pass_ticket =>  $self->pass_ticket) if $self->pass_ticket;
    my $json = $self->http_post($self->gen_url2($api,@query_string),{Referer=>'https://'.$self->domain . '/',json=>1},json=>$post);
    return unless defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    my @friends;
    my @groups;
    for my $e (@{$json->{ContactList}}){
        if($self->is_group($e->{UserName})){
            my $group = {};
            for(keys %KEY_MAP_GROUP){
                $group->{$_} = defined $e->{$KEY_MAP_GROUP{$_}}?encode("utf8",$e->{$KEY_MAP_GROUP{$_}}):"";
            }
            for my $m (@{$e->{MemberList}}){
                my $member = {};
                for(keys %KEY_MAP_GROUP_MEMBER){
                    $member->{$_} = defined $m->{$KEY_MAP_GROUP_MEMBER{$_}}?encode("utf8", $m->{$KEY_MAP_GROUP_MEMBER{$_}} ):"";
                }
                $member->{sex} = $self->code2sex($member->{sex});
                push @{$group->{member}},$member;
            }
            push @groups,$group;
        }
        else{
            my $friend = {};
            for(keys %KEY_MAP_FRIEND){
                $friend->{$_} = defined $e->{$KEY_MAP_FRIEND{$_}}?encode("utf8",$e->{$KEY_MAP_FRIEND{$_}}):"";
            }
            $friend->{sex} = $self->code2sex($friend->{sex});
            push @friends,$friend;
        }
    }
    return [\@friends,\@groups];
}

1;

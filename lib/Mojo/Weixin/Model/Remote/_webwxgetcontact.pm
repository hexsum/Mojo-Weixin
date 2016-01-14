use Mojo::Util qw(url_escape encode);
use Mojo::Weixin::Const;
sub Mojo::Weixin::_webwxgetcontact {
    my $self = shift;
    my $api = "https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxgetcontact";
    my @query_string = (
        lang        =>  'zh_CN',
        pass_ticket =>  $self->pass_ticket,
        r           =>  $self->now(),
        seq         =>  0,
        skey        =>  $self->skey,
    );

    my $json = $self->http_post($self->gen_url($api,@query_string),{Referer=>'https://wx.qq.com/?&lang=zh_CN',json=>1},json=>{});
    return unless defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    return if $json->{MemberCount} == 0;
    my @friends;
    my @groups;
    for my $e ( @{ $json->{MemberList} } ){
        if($self->is_group($e->{UserName})){
            my $group = {};
            for(keys %KEYP_MAP_GROUP){
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
                $friend->{$_} = defined $e->{$KEY_MAP_FRIEND{$_}}?encode("utf8",$e->{$KEY_MAP_FRIEND{$_}}):"" ;
            }
            $friend->{sex} = $self->code2sex($friend->{sex});
            push @friends,$friend;
        }
    }
    return [\@friends,\@groups];
}
    
1;

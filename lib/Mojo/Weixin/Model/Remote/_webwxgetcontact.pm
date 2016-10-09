use Mojo::Util qw(url_escape encode);
use strict;
use Mojo::Weixin::Const qw(%KEY_MAP_USER %KEY_MAP_GROUP %KEY_MAP_GROUP_MEMBER %KEY_MAP_FRIEND);
sub Mojo::Weixin::_webwxgetcontact {
    my $self = shift;
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxgetcontact";
    my @query_string = (
        r           =>  $self->now(),
        seq         =>  0,
        skey        =>  $self->skey,
    );
    push @query_string,(pass_ticket=>Mojo::Util::url_escape($self->pass_ticket)) if $self->pass_ticket;

    my $json = $self->http_post($self->gen_url($api,@query_string),{Referer=>'https://'.$self->domain . '/',json=>1},json=>{});
    return unless defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    return if $json->{MemberCount} == 0;
    my @friends;
    my @groups;
    for my $e ( @{ $json->{MemberList} } ){
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
                $friend->{$_} = defined $e->{$KEY_MAP_FRIEND{$_}}?encode("utf8",$e->{$KEY_MAP_FRIEND{$_}}):"" ;
            }
            $friend->{sex} = $self->code2sex($friend->{sex});
            push @friends,$friend;
        }
    }
    return [\@friends,\@groups];
}
    
1;

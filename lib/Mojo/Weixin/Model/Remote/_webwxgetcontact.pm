use strict;
use Mojo::Weixin::Const qw(%KEY_MAP_USER %KEY_MAP_GROUP %KEY_MAP_GROUP_MEMBER %KEY_MAP_FRIEND);
sub Mojo::Weixin::_webwxgetcontact {
    my $self = shift;
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxgetcontact";
    my $flag = 0;
    my $seq = 0;
    my @friends;
    my @groups;
    do {
        my @query_string = (
            r           =>  $self->now(),
            seq         =>  $seq,
            skey        =>  $self->skey,
        );
        push @query_string,(pass_ticket=>$self->url_escape($self->pass_ticket)) if $self->pass_ticket;

        my $json = $self->http_get($self->gen_url($api,@query_string),{Referer=>'https://'.$self->domain . '/',json=>1});
        #return [\@friends,\@groups] if not defined $json;
        return if not defined $json;
        return if $json->{BaseResponse}{Ret}!=0;
        return if $json->{MemberCount} == 0;
        if ($self->is_update_all_friend and defined $json->{Seq} and $json->{Seq} != 0){#获取的不全，需要继续获取其余部分
            $flag = 1 ;
            $seq = $json->{Seq};
        }
        else{
            $flag = 0;
        }
        for my $e ( @{ $json->{MemberList} } ){
            if($self->is_group_id($e->{UserName})){
                my $group = {};
                for(keys %KEY_MAP_GROUP){
                    $group->{$_} = $e->{$KEY_MAP_GROUP{$_}} // "";
                }
                for my $m (@{$e->{MemberList}}){
                    my $member = {};
                    for(keys %KEY_MAP_GROUP_MEMBER){
                        $member->{$_} = $m->{$KEY_MAP_GROUP_MEMBER{$_}} // "";
                    }
                    $member->{sex} = $self->code2sex($member->{sex});
                    push @{$group->{member}},$member;
                }
                push @groups,$group;
            }
            else{
                my $friend = {};
                for(keys %KEY_MAP_FRIEND){
                    $friend->{$_} = $e->{$KEY_MAP_FRIEND{$_}} // "" ;
                }
                $friend->{sex} = $self->code2sex($friend->{sex});
                push @friends,$friend;
            }
        }
    } while $flag;
    return [\@friends,\@groups];
}
    
1;

use Mojo::Util qw(encode url_escape);
use strict;
use List::Util qw(first);
use Mojo::Weixin::Const qw(%KEY_MAP_USER %KEY_MAP_GROUP %KEY_MAP_GROUP_MEMBER %KEY_MAP_FRIEND);
sub Mojo::Weixin::_webwxinit{
    my $self = shift;
    my $api = "https://". $self->domain . "/cgi-bin/mmwebwx-bin/webwxinit";
    my @query_string = (
        r           =>  sub{use integer;unpack 'i',~ pack 'l',$self->now() & 0xFFFFFFFF}->(),
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
    
    my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://'.$self->domain .'/'},json=>$post);
    return if not defined $json;
    return if $json->{BaseResponse}{Ret}!=0;
    $self->sync_key($json->{SyncKey}) if $json->{SyncKey}{Count} !=0;
    $self->skey($json->{Skey}) if $json->{Skey};
    my $user = {};
    for(keys %KEY_MAP_USER){
        $user->{$_} = defined $json->{User}{$KEY_MAP_USER{$_}}?encode("utf8",$json->{User}{$KEY_MAP_USER{$_}} ) : "";
    }

    my @friends;
    my @groups;
    for my $e (@{ $json->{ContactList} }){
        if($self->is_group($e->{UserName})){
            my $group = {};
            for(keys %KEY_MAP_GROUP){
                $group->{$_} = defined $e->{$KEY_MAP_GROUP{$_}}?encode("utf8",$e->{$KEY_MAP_GROUP{$_}}):"";
            }
            for my $m (@{$e->{MemberList}}){
                my $member = {_group_id=>$group->{id}};
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
    
    my @id = $json->{ChatSet}?split /,/,$json->{ChatSet}:();
    for(@id){
        if($self->is_group($_)){
            push @groups,{id=>$_}; 
        }
        else{
            push @friends,{id=>$_};
        }
    }
    return [$user,\@friends,\@groups];
}
1

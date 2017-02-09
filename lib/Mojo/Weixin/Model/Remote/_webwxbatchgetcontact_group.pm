use strict;
use Mojo::Weixin::Const qw(%KEY_MAP_GROUP %KEY_MAP_GROUP_MEMBER);
use Mojo::Weixin::Model::Remote::_webwxbatchgetcontact_group_member;
sub Mojo::Weixin::_webwxbatchgetcontact_group{
    my $self  = shift;
    my $is_update_group_member_detail = shift // 1;
    my @ids = @_;
    my @return;
    my $api = "https://".$self->domain . "/cgi-bin/mmwebwx-bin/webwxbatchgetcontact";

    while( my @id = splice(@ids,0,50) ){
        my @query_string = (
            type        =>  "ex",
            r           =>  $self->now(),
        );
        push @query_string,(pass_ticket =>  $self->pass_ticket) if $self->pass_ticket;
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
        my $json = $self->http_post($self->gen_url2($api,@query_string),{Referer=>'https://'.$self->domain . '/',json=>1},json=>$post);
        next unless defined $json;
        next if $json->{BaseResponse}{Ret}!=0;
        for my $e (@{$json->{ContactList}}){
            next if not $self->is_group_id($e->{UserName});
            my $group = {};
            for(keys %KEY_MAP_GROUP){
                $group->{$_} = $e->{$KEY_MAP_GROUP{$_}} // "";
            }
            if($is_update_group_member_detail){
                my @member = $self->_webwxbatchgetcontact_group_member($group->{_eid},map {$_->{UserName}} @{$e->{MemberList}});
                if(@member){
                    $group->{member} = \@member;
                }
                else{
                    for my $m (@{$e->{MemberList}}){
                        my $member = {};
                        for(keys %KEY_MAP_GROUP_MEMBER){
                            $member->{$_} = $m->{$KEY_MAP_GROUP_MEMBER{$_}} // "";
                        }
                        $member->{sex} = $self->code2sex($member->{sex});
                        push @{$group->{member}},$member;
                    }
                }
            }
            else{
                for my $m (@{$e->{MemberList}}){
                    my $member = {};
                    for(keys %KEY_MAP_GROUP_MEMBER){
                        $member->{$_} = $m->{$KEY_MAP_GROUP_MEMBER{$_}} // "";
                    }
                    $member->{sex} = $self->code2sex($member->{sex});
                    push @{$group->{member}},$member;
                }
            }
            push @return,$group;
        }

    }
    return if @return ==0;
    return wantarray?@return:$return[0];
}

1;

use Mojo::Util qw(decode url_escape);
sub Mojo::Weixin::_webwxupdatechatroom {
    my $self = shift;
    my $fun = shift;
    my $api = 'https://' .$self->domain . '/cgi-bin/mmwebwx-bin/webwxupdatechatroom';
    if($fun eq "mod"){
        my $group = shift;
        my $displayname = shift; 
        if(not defined $displayname){
            $self->error("_webwxupdatechatroom invaild displayname");
            return;
        }
        my @query_string = (
            fun => 'modtopic',
        );
        push @query_string,(pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
        my $post = {
            BaseRequest =>  {
                Uin         =>  $self->wxuin,
                Sid         =>  $self->wxsid,
                Skey        =>  $self->skey,
                DeviceID    =>  $self->deviceid,
            },
            ChatRoomName    =>  $group->id,
            NewTopic        =>  decode("utf8",$displayname),
        };

        my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post); 
        return if not defined $json;
        return if $json->{BaseResponse}{Ret}!=0;
        return 1;
    }
    elsif($fun eq "add"){
        my $group = shift;
        my @member = @_;
        my $mode = ($group->members + @member)>=40?'invitemember':'addmember';
        my @query_string = (
            fun => $mode,
        );
        push @query_string,(pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
        my $post = {
            BaseRequest =>  {
                Uin         =>  $self->wxuin,
                Sid         =>  $self->wxsid,
                Skey        =>  $self->skey,
                DeviceID    =>  $self->deviceid,
            },
            ChatRoomName    =>  $group->id,
        }; 
        $post->{($mode eq 'invitemember'?'InviteMemberList':'AddMemberList')} = join(",",map{ $_->id } @member);
        my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post);
        return if not defined $json;
        return if $json->{BaseResponse}{Ret}!=0;
        return 1;
    }
    elsif($fun eq "del"){
        my $group = shift;
        my @member = @_;
        my @query_string = (
            fun => 'delmember',
        );
        push @query_string,(pass_ticket =>  url_escape($self->pass_ticket)) if $self->pass_ticket;
        my $post = {
            BaseRequest =>  {
                Uin         =>  $self->wxuin,
                Sid         =>  $self->wxsid,
                Skey        =>  $self->skey,
                DeviceID    =>  $self->deviceid,
            },
            ChatRoomName    =>  $group->id,
            DelMemberList   =>  join(",",map{ $_->id } @member),
        };
        my $json = $self->http_post($self->gen_url($api,@query_string),{json=>1,Referer=>'https://' . $self->domain . '/'},json=>$post);
        return if not defined $json;
        return if $json->{BaseResponse}{Ret}!=0;
        return 1;
        
    }
}
1;


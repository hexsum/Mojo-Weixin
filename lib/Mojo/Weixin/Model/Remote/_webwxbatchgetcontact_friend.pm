use strict;
use Mojo::Weixin::Const qw(%KEY_MAP_FRIEND);
sub Mojo::Weixin::_webwxbatchgetcontact_friend{
    my $self  = shift;
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
            List        =>  [ map { {UserName=>$_,EncryChatRoomId=>""} } @id ],
        };
        my $json = $self->http_post($self->gen_url2($api,@query_string),{Referer=>'https://'.$self->domain . '/',json=>1},json=>$post);
        next unless defined $json;
        next if $json->{BaseResponse}{Ret}!=0;
        for my $e (@{$json->{ContactList}}){
            my $friend = {};
            for(keys %KEY_MAP_FRIEND){
                $friend->{$_} = $e->{$KEY_MAP_FRIEND{$_}} // "";
            }
            $friend->{sex} = $self->code2sex($friend->{sex});
            push @return,$friend;
        }

    }
    return if @return ==0;
    return wantarray?@return:$return[0];
}

1;

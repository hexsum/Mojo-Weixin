package Mojo::Weixin::Plugin::Beauty;
our $PRIORITY = 95;
sub call{
    my $client = shift;
    my $data = shift;
    my @pins;
    my $last_pin_id;
    my $command = $data->{command} || '看妹子';
    my $html = $client->http_get("http://huaban.com/favorite/beauty/");
    if(not defined $html){
        $self->error("插件[ ".__PACKAGE__ . " ]初始化数据失败");
        return;
    }
    if($html=~m#\Qapp.page["pins"]\E\s*=\s*(.*);#){
        my $json = $client->decode_json($1);
        push @pins,{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}} for @$json;
    }

    if(@pins == 0){
        $self->error("插件[ ".__PACKAGE__ . " ]初始化数据失败");
        return;
    }

    my $callback = sub{
        my($client,$msg) = @_;
        return if $msg->content ne $command; 
        $msg->allow_plugin(0);
        my $pin = shift @pins;
        if(not defined $pin){
            $self->http_get(
                'http://huaban.com/favorite/beauty/?ilf1frwr&max='. $last_pin_id . '&limit=20&wfl=1',
                {
                    Accept=>'application/json',
                    Referer=>'http://huaban.com/favorite/beauty/',
                    'X-Request'=>'JSON',
                    'X-Requested-With'=>'XMLHttpRequest',
                    json=>1,
                },
                sub{
                    my $json = shift;
                    return if not defined $json;
                    push @pins,{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}} for @{$json->{pins}};
                    my $pin = shift @pins;
                    if($msg->type eq "group_message"){
                        $client->send_media($msg->group,$pin->{url});
                    }
                    elsif($msg->type eq "friend_message"){
                        $client->send_media($msg->sender,$pin->{url});
                    }
                    $last_pin_id = $pin->{id};
                }
            );
        }
        else{
            if($msg->type eq "group_message"){
                $client->send_media($msg->group,$pin->{url});
            }
            elsif($msg->type eq "friend_message"){
                $client->send_media($msg->sender,$pin->{url});
            }
            $last_pin_id = $pin->{id};
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}

1;

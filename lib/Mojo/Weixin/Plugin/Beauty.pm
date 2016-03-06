package Mojo::Weixin::Plugin::Beauty;
our $PRIORITY = 95;
use Storable qw(retrieve nstore);
sub call{
    my $client = shift;
    my $data = shift;
    my $command = $data->{command} || '看妹子';
    my $board = $data->{board} || 'http://huaban.com/boards/19570858/';
    my $file = $data->{file} || './Beauty.dat';
    my $db = {pins=>[],last_pin_id=>undef,board=>$board};
    $db = retrieve($file) if -e $file;
    if(defined $db->{board}  and $db->{board} ne $board){
        $db = {pins=>[],last_pin_id=>undef,board=>$board};
    }
    #my $html = $client->http_get("http://huaban.com/favorite/beauty/");
    my $html = $client->http_get($db->{board});
    if(defined $html){
        if($html=~m#\Qapp.page["board"]\E\s*=\s*(.*?);#){
            my $json = $client->decode_json($1);
            push @{$db->{pins}},{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}} for @{$json->{pins}};
        }
    }

    if(@{$db->{pins}} == 0){
        $self->error("插件[ ".__PACKAGE__ . " ]初始化数据失败");
        return;
    }

    my $callback = sub{
        my($client,$msg) = @_;
        return if $msg->content ne $command; 
        return if $msg->from eq "bot";
        $msg->allow_plugin(0);
        my $pin = shift @{$db->{pins}};
        if(not defined $pin){
            $self->http_get(
                $db->{board} . '?ilf1frwr&max='. $db->{last_pin_id} . '&limit=20&wfl=1',
                {
                    Accept=>'application/json',
                    Referer=>$db->{board},
                    'X-Request'=>'JSON',
                    'X-Requested-With'=>'XMLHttpRequest',
                    json=>1,
                },
                sub{
                    my $json = shift;
                    return if not defined $json;
                    push @{$db->{pins}},{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}} for @{$json->{pins}};
                    my $pin = shift @{$db->{pins}};
                    if($msg->type eq "group_message"){
                        $client->send_media($msg->group,$pin->{url},sub{$_[1]->from("bot")});
                    }
                    elsif($msg->type eq "friend_message" and $msg->class eq "recv"){
                        $client->send_media($msg->sender,$pin->{url},sub{$_[1]->from("bot")});
                    }
                    elsif($msg->type eq "friend_message" and $msg->class eq "send"){
                        $client->send_media($msg->receiver,$pin->{url},sub{$_[1]->from("bot")});
                    }
                    $db->{last_pin_id} = $pin->{id};
                    nstore($db,$file);
                }
            );
        }
        else{
            if($msg->type eq "group_message"){
                $client->send_media($msg->group,$pin->{url},sub{$_[1]->from("bot")});
            }
            elsif($msg->type eq "friend_message" and $msg->class eq "recv"){
                $client->send_media($msg->sender,$pin->{url},sub{$_[1]->from("bot")});
            }
            elsif($msg->type eq "friend_message" and $msg->class eq "send"){
                $client->send_media($msg->receiver,$pin->{url},sub{$_[1]->from("bot")});
            }
            $db->{last_pin_id} = $pin->{id};
            nstore($db,$file);
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}

1;

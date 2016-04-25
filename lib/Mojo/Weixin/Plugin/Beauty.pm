package Mojo::Weixin::Plugin::Beauty;
our $PRIORITY = 95;
use Storable qw(retrieve nstore);
use List::Util qw(first);
sub call{
    my $client = shift;
    my $data = shift;
    my $file = $data->{file} || './Beauty.dat';
    my $db = {};$db = retrieve($file) if -e $file;
    my $boards = ref($data->{board}) eq "ARRAY"? $data->{board}: [{command=>"看妹子",url=>'http://huaban.com/boards/19570858/'}];
    for(@{ $boards }){
        my $command = $_->{command} ;
        my $url = $_->{url};
        next if not $command;
        next if not $url;
        if(not exists $db->{$url}){
            $db->{$url} = {command=>$command,pins=>[],last_pin_id=>undef,url=>$url};
        }
        else{
            $db->{$url}{command} = $command;
            $db->{$url}{url} = $url;
        }
    }
    for my $url (keys %$db){
        if(not first {$url eq $_->{url} } @{ $boards } ){
            delete $db->{$url};
            next;
        }
        if(@{$db->{$url}{pins}} != 0){
            $db->{$url}{last_pin_id} = $db->{$url}{pins}->[-1]->{id} if not defined $db->{$url}{last_pin_id};
            next ;
        }
        my $html = $client->http_get($url);
        if(defined $html){
            if($html=~m#\Qapp.page["board"]\E\s*=\s*(.*?);#){
                my $data = $1;
                my $json = $client->decode_json($data);
                if(defined $json and defined  $json->{pins}){
                    for(@{ $json->{pins} }){
                        push @{$db->{$url}{pins}},{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}};
                    }
                }
            }
        }
        if(@{$db->{$url}{pins}} == 0){
            $client->error("插件[ ".__PACKAGE__ . " ]初始化数据失败: [$db->{$url}{command}]($url)");
        }
        else{
            $db->{$url}{last_pin_id} = $db->{$url}{pins}->[-1]->{id};
        }
    }

    my $callback = sub{
        my($client,$msg) = @_;
        my $command = $msg->content;
        my $board = first { $command eq $_->{command}} values %$db ;
        return if not defined $board;
        return if $msg->from eq "bot";
        $msg->allow_plugin(0);
        my $pin = shift @{$board->{pins}};
        if(not defined $pin){
            $client->http_get(
                $board->{url} . '?ilf1frwr&max='. $board->{last_pin_id} . '&limit=20&wfl=1',
                {
                    Accept=>'application/json',
                    Referer=>$board->{url},
                    'X-Request'=>'JSON',
                    'X-Requested-With'=>'XMLHttpRequest',
                    json=>1,
                },
                sub{
                    my $json = shift;
                    return if not defined $json;
                    if(defined $json->{board}{pins} ){
                        if(@{$json->{board}{pins}} > 0){
                            push @{$board->{pins}},{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}} for @{$json->{board}{pins}};
                        }
                        else{
                            my $html = $client->http_get($board->{url});
                            if(defined $html){
                                if($html=~m#\Qapp.page["board"]\E\s*=\s*(.*?);#){
                                    my $data = $1;
                                    my $json = $client->decode_json($data);
                                    if(defined $json and defined  $json->{pins}){
                                        for(@{ $json->{pins} }){
                                            push @{$board->{pins}},{id=>$_->{pin_id}, url=>'http://img.hb.aicdn.com/' . $_->{file}{key}};
                                        }
                                    }
                                }
                            }
                        }
                    }
                    my $pin = shift @{$board->{pins}};
                    if($msg->type eq "group_message"){
                        $client->send_media($msg->group,$pin->{url},sub{$_[1]->from("bot")});
                    }
                    elsif($msg->type eq "friend_message" and $msg->class eq "recv"){
                        $client->send_media($msg->sender,$pin->{url},sub{$_[1]->from("bot")});
                    }
                    elsif($msg->type eq "friend_message" and $msg->class eq "send"){
                        $client->send_media($msg->receiver,$pin->{url},sub{$_[1]->from("bot")});
                    }
                    $board->{last_pin_id} = $pin->{id};
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
            $board->{last_pin_id} = $pin->{id};
            nstore($db,$file);
        }
    };
    $client->on(receive_message=>$callback,send_message=>$callback);
}

1;

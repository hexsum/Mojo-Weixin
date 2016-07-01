package Mojo::Weixin::Plugin::XiaoiceReply;
our $PRIORITY = 1;
sub call{
    my $client = shift;
    my $data = shift;
    my $is_need_at = defined $data->{is_need_at}?$data->{is_need_at}:1;
    my $command_on = $data->{comamnd_on} || "小冰启动";
    my $command_off = $data->{comamnd_off} || "小冰停止";
    my $onoff_flag = 1;
    my @db;

    $client->on(ready=>sub{
        #支持绑定的两个对象之间互相转发消息
        my $xiaoice = $client->search_friend(account=>'ms-xiaoice');
        if(not defined $xiaoice){
            $client->error("未能在通讯录中搜索到 微软小冰 帐号信息，请确认是否已经关注 微软小冰 公众号");
            return;
        }
        $client->interval($data->{ttl}||30,sub{@db=()});
        $client->on(login=>sub{@db=()});
        $client->on(send_message=>sub{
            my($client,$msg) = @_;
            if($msg->content eq $command_on){$onoff_flag = 1;$msg->reply("小冰已经启动");}
            elsif($msg->content eq $command_off){$onoff_flag = 0;$msg->reply("小冰已经停止");}
        });

        $client->on(receive_message=>sub{
            my($client,$msg) = @_;
            return if not $msg->allow_plugin;
            return if not $onoff_flag;
            return if $is_need_at and $msg->type eq "group_message" and !$msg->is_at;
            my $xiaoice = $client->search_friend(account=>'ms-xiaoice');
            if(not defined $xiaoice){
                $client->error("未能在通讯录中搜索到 微软小冰 帐号信息，请确认是否已经关注 微软小冰 公众号");
                return;
            }
            if($msg->sender->id eq $xiaoice->id){
                my $binder = $db[0];
                return if not defined $binder;
                if($msg->format eq "media" and -e $msg->media_path){
                    $binder->send_media($msg->media_path);
                }
                else{
                    $binder->send($msg->content);
                }
            }
            else{
                my $object = $msg->type eq "group_message"?$msg->group:$msg->sender;
                if (@db == 0){
                    $db[0] = $object;
                    $msg->remove_at();
                    if($msg->format eq "media" and -e $msg->media_path){
                        $xiaoice->send_media($msg->media_path);
                    }
                    else{
                        $xiaoice->send($msg->content);
                    }
                }
                elsif(@db > 0 and $db[0]->id eq $object->id){
                    $msg->remove_at();
                    if($msg->format eq "media" and -e $msg->media_path){
                        $xiaoice->send_media($msg->media_path);
                    }
                    else{
                        $xiaoice->send($msg->content); 
                    }
                }
            } 
        });
    });

}
1;

package Mojo::Weixin::Plugin::XiaoiceReply;
our $PRIORITY = 1;
use List::Util qw(first);
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
        my $xiaoice = $client->search_friend(account=>'xiaoice-ms');
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
            return if $msg->type !~ /^friend_message|group_message$/;
            return if $msg->format !~ /^text|media$/;
            return if not $msg->allow_plugin;
            return if not $onoff_flag;
            my $xiaoice = $client->search_friend(account=>'xiaoice-ms');
            if(not defined $xiaoice){
                $client->error("未能在通讯录中搜索到 微软小冰 帐号信息，请确认是否已经关注 微软小冰 公众号");
                return;
            }
            if($msg->sender->id ne $xiaoice->id){
                if($msg->type eq "group_message"){
                    return if defined $data->{allow_group_reply} and !$data->{allow_group_reply};
                    return if ref $data->{ban_group}  eq "ARRAY" and first {$msg->group->displayname eq $_} @{$data->{ban_group}};
                    return if ref $data->{allow_group}  eq "ARRAY" and !first {$msg->group->displayname eq $_} @{$data->{allow_group}};
                    return if ref $data->{ban_group_member}  eq "ARRAY" and first {$msg->sender->displayname eq $_} @{$data->{ban_group_user}};
                    return if ref $data->{allow_group_member}  eq "ARRAY" and !first {$msg->sender->displayname eq $_} @{$data->{allow_group_user}};
                    return if $is_need_at and !$msg->is_at;
                }
                else{
                    return if defined $data->{allow_friend_reply} and !$data->{allow_friend_reply};
                    return if ref $data->{ban_friend} eq "ARRAY" and first {$msg->sender->displayname eq $_} @{$data->{ban_user}};
                    return if ref $data->{allow_friend} eq "ARRAY" and !first {$msg->sender->displayname eq $_} @{$data->{allow_user}};
                }
            }
            if($msg->sender->id eq $xiaoice->id){
                my $binder = $db[0];
                return if not defined $binder;
                if($msg->format eq "media" and (defined $msg->media_id or  -e $msg->media_path) ){
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
                    if($msg->format eq "media" and (defined $msg->media_id or -e $msg->media_path) ){
                        $xiaoice->send_media($msg->media_path);
                    }
                    else{
                        $xiaoice->send($msg->content);
                    }
                }
                elsif(@db > 0 and $db[0]->id eq $object->id){
                    $msg->remove_at();
                    if($msg->format eq "media" and (defined $msg->media_id or -e $msg->media_path )){
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

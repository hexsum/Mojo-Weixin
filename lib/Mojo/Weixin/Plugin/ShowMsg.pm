package Mojo::Weixin::Plugin::ShowMsg;
our $PRIORITY = 100;
use POSIX qw(strftime);
sub call{
    my $client = shift;
    $client->on(
        receive_message=>sub{
            my($client,$msg)=@_; 
            if($msg->type eq 'friend_message'){
                my $sender_nick = $msg->sender->displayname;
                my $sender_category = "好友";
                #my $receiver_nick = $msg->receiver->nick;
                my $receiver_nick = "我";
                $client->info({time=>$msg->time,level=>"好友消息",title=>"$sender_nick|$sender_category :"},$msg->content);
                
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->displayname;
                my $sender_nick = $msg->sender->displayname;
                $client->info({time=>$msg->time,level=>"群消息",title=>"$sender_nick|$gname :"},$msg->content);
            }
        },
        send_message=>sub{
            my($client,$msg,$status)=@_;
            my $attach = $status->is_success?"":"[发送失败".(defined $status->info?"(".$status->info.")":"") . "]";
            if($msg->type eq 'friend_message'){
                my $sender_nick = "我";
                my $receiver_nick = $msg->receiver->displayname;
                $client->info({time=>$msg->time,level=>"好友消息",title=>"$sender_nick->$receiver_nick :"},$msg->content . $attach);
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->displayname;
                my $sender_nick = "我";
                $client->info({time=>$msg->time,level=>"群消息",title=>"$sender_nick->$gname :"},$msg->content . $attach);
            }
        },
    );
}

1

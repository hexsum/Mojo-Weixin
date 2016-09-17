package Mojo::Weixin::Plugin::ShowMsg;
our $PRIORITY = 100;
use POSIX qw(strftime);
sub call{
    my $client = shift;
    $client->on(
        friend_request =>sub{
            my($client,$id,$displayname,$verify,$ticket) = @_;
            $client->info({time=>time,level=>'系统消息',title=>"好友推荐消息|系统帐号 :"},"收到[ " . $displayname  . " ]好友验证请求：" . ($verify?$verify:"(验证内容为空)"));
        },
        new_group => sub{
            my $group  = $_[1];
            $client->info("新增群组：" . $group->displayname);
        },
        lose_group=>sub{
            my $group  = $_[1];
            $client->info("退出群组：" . $group->displayname)
        },
        new_group_member=>sub{
            my $member  = $_[1];
            $client->info("新增群成员：" . $member->displayname . "|" . $member->group->displayname);
        },
        lose_group_member=>sub{
            my $member  = $_[1];
            $client->info("删除群成员：" . $member->displayname . "|" . $member->group->displayname);
        },
        new_friend=>sub{
            my $friend  = $_[1];
            $client->info("新增好友：" . $friend->displayname);
        },
        lose_friend=>sub{
            my $friend  = $_[1];
            $client->info("删除好友：" . $friend->displayname);
        },
        receive_message=>sub{
            my($client,$msg)=@_; 
            if($msg->type eq 'friend_message'){
                my $sender_nick = $msg->sender->displayname;
                my $sender_category = $msg->sender->category || "未知";
                my $level = $sender_category eq '系统帐号'?"系统消息":"好友消息";
                #my $receiver_nick = $msg->receiver->nick;
                my $receiver_nick = "我";
                $client->info({time=>$msg->time,level=>$level,title=>"$sender_nick|$sender_category :"},$msg->content);
                
            }
            elsif($msg->type eq 'group_message'){
                my $gname = $msg->group->displayname;
                my $sender_nick = $msg->sender->displayname;
                $client->info({time=>$msg->time,level=>"群消息",title=>"$sender_nick|$gname :"},$msg->content);
            }
            elsif($msg->type eq 'group_notice'){
                my $gname = $msg->group->displayname;
                $client->info({time=>$msg->time,level=>"群提示",title=>"$gname :"},$msg->content);
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

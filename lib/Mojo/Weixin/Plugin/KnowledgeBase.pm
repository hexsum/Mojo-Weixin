package Mojo::Weixin::Plugin::KnowledgeBase;
$Mojo::Weixin::Plugin::KnowledgeBase::PRIORITY = 2;

use Storable qw(retrieve nstore);
sub call{
    my $client = shift;
    my $data = shift;
    my $file = $data->{file} || './KnowledgeBase.dat';
    my $base = {};
    $base = retrieve($file) if -e $file;
    #$client->timer(120,sub{nstore $base,$file});
    my $callback = sub{
        my($client,$msg) = @_;
        return if $msg->type !~ /^friend_message|group_message$/;
        if($msg->content =~ /^(?:learn|学习)
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            /xs){
            $msg->allow_plugin(0);
            my($q,$a) = ($1,$2);
            return unless defined $q;
            return unless defined $a;
            my $space = $msg->type eq "friend_message"?"__我的好友__":$msg->group->displayname;
            $q=~s/^\s+|\s+$//g;
            $a=~s/^\s+|\s+$//g;
            push @{ $base->{$space}{$q} }, $a;
            nstore($base,$file);
            $client->reply_message($msg,"知识库[ $q -> $a ]添加成功",sub{$_[1]->from("bot")}); 

        }   
        elsif($msg->content =~ /^(?:del|delete|删除)
                            \s+
                            (?|"([^"]+)"|'([^']+)'|([^\s"']+))
                            /xs){
            $msg->allow_plugin(0);
            #return if $msg->sender->id ne $client->user->id;
            my($q) = ($1);
            $q=~s/^\s+|\s+$//g;
            return unless defined $q;
            my $space = $msg->type eq "friend_message"?"__我的好友__":$msg->group->displayname;
            delete $base->{$space}{$q}; 
            nstore($base,$file);
            $client->reply_message($msg,"知识库[ $q ]删除成功"),sub{$_[1]->from("bot")};
        }
        else{
            return if $msg->from eq "bot";
            my $content = $msg->content;
            my $space = $msg->type eq "friend_message"?"__我的好友__":$msg->group->displayname;
            return unless exists $base->{$space}{$content};
            $msg->allow_plugin(0);
            my $len = @{$base->{$space}{$content}};
            $client->reply_message($msg,$base->{$space}{$content}->[int rand $len],sub{$_[1]->from("bot")});
        }
    };
    $client->on(receive_message=>$callback);
    $client->on(send_message=>$callback);
}
1;

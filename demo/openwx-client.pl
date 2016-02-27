#!/usr/bin/env perl
=encoding utf8
=head1 SYNOPSIS
使用帮助

-h          打印帮助内容
-id         对象(好友、群成员、讨论组成员)的id
-account    对象(好友、群成员、讨论组成员)的帐号

发送消息示例： 

    perl ./openwx-client.pl -id @329be1b81d62b7c507e9329d2a47d4a0 你好

    perl ./openwx-client.pl -account test 你好

=cut
use strict;
use Getopt::Long;
use Mojo::UserAgent;
use Mojo::Util qw(url_escape encode decode);
my %API = (
    send_message         =>  'http://127.0.0.1:3000/openwx/send_message',
);
my $ua = Mojo::UserAgent->new;
if($ARGV[0] eq "-l" or $ARGV[0] eq "-list"){
    my $friend = $ua->get("http://127.0.0.1:3000/openwx/get_friend_info")->res->json;
    print "好友:\n";
    for(@{$friend}){
        print encode("utf8",$_->{displayname}) || "NULL","\t",$_->{id},"\n";
    }
    print "=====\n";
    print "群组:\n";
    my $group = $ua->get("http://127.0.0.1:3000/openwx/get_group_info")->res->json;
    for(@{$group}){
        print encode("utf8",$_->{displayname}) || "NULL","\t",$_->{id},"\n";
    }
    exit;
}
elsif(@ARGV == 0 or $ARGV[0] eq "-h" or $ARGV[0] eq "--help"){
    print <<USAGE;

使用帮助

-h          打印帮助内容
-id         对象(好友、群成员、讨论组成员)的id
-account    对象(好友、群成员、讨论组成员)的帐号

发送消息示例：

    perl ./openwx-client.pl -id @329be1b81d62b7c507e9329d2a47d4a0 你好

    perl ./openwx-client.pl -account test 你好
USAGE
exit;
}
my ($id,$account,@content,$content);
GetOptions (
    "id=s" => \$id,
    "account=s" => \$account,
    "<>"    =>  sub{push @content ,$_[0]},
)or die $!;
$content = join " ",@content;
$content=~s/\\n/\n/g;
$content = url_escape( $content);
die "需要输入发送内容\n" unless defined $content;

my $tx;
if(defined $id){
    $tx = $ua->get($API{"send_message"} . "?id=$id&content=$content");
}
elsif(defined $account){
    $tx = $ua->get($API{"send_message"} . "?account=$account&content=$content");
}
else{
    die "参数错误\n";
}
warn $tx->req->to_string;
warn $tx->res->to_string;

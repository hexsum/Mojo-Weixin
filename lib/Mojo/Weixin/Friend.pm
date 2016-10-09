package Mojo::Weixin::Friend;
use Mojo::Weixin::Base 'Mojo::Weixin::Model::Base';
use List::Util qw(first);
has name => '昵称未知';
has [qw( 
    account
    province
    city
    sex
    id
    signature
    display
    markname
    _avatar
    _verifyflag
)];
has 'category' => '好友'; #系统帐号|公众号|好友

my %special_id = map {$_=>undef} ("filehelper","fmessage","newsapp","weibo", "qqmail", "tmessage", "qmessage", "qqsync", "floatbottle", "lbsapp", "shakeapp", "medianote", "qqfriend", "readerapp", "blogapp", "facebookapp", "masssendapp", "meishiapp", "feedsapp", "voip", "blogappweixin", "brandsessionholder", "weixinreminder", "wxid_novlwrv3lqwv11", "gh_22b87fa7cb3c", "officialaccounts", "notification_messages");

sub new {
    my $self = shift;
    $self = $self->Mojo::Weixin::Base::new(@_);
    $self->client->emoji_convert(\$self->{name},$self->client->emoji_to_text);
    if(exists $special_id{$self->id}){
        $self->category("系统帐号");
    }
    elsif(defined $self->_verifyflag and $self->_verifyflag & 8){
        $self->category("公众号");
    }
    $self;
}
sub get_avatar{
    my $self = shift;
    $self->client->get_avatar($self,@_);
}

sub displayname{
    my $self = shift;
    return $self->display || $self->markname || $self->name;
}

sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$hash){
        if(exists $hash->{$_}){
            $self->client->emoji_convert(\$hash->{$_},$self->client->emoji_to_text) if $_ eq "name";
            if(defined $hash->{$_} and defined $self->{$_}){
                if($hash->{$_} ne $self->{$_}){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->client->emit("friend_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->client->emit("friend_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
            }
        }
    }
    $self;

}

sub send{
    my $self = shift;
    $self->client->send_message($self,@_);
}
sub send_media{
    my $self = shift;
    $self->client->send_media($self,@_);
}
sub set_markname {
    my $self = shift;
    $self->client->set_friend_markname($self,@_);
}
1;

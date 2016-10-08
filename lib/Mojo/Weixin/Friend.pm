package Mojo::Weixin::Friend;
use Mojo::Weixin::Base 'Mojo::Weixin::Model::Base';
use List::Util qw(first);
has name => '昵称未知';
has [qw( 
    account
    avatar
    province
    city
    sex
    id
    signature
    display
    markname
)];
has 'category' => '好友'; #系统帐号|公众号|好友

sub new {
    my $self = shift;
    $self = $self->Mojo::Weixin::Base::new(@_);
    $self->client->emoji_convert(\$self->{name},$self->client->emoji_to_text);
    if(first { $self->id eq $_ } qw(fmessage weixin filehelper)){
        $self->category("系统帐号");
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

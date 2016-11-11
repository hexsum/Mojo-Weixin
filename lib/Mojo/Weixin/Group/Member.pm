package Mojo::Weixin::Group::Member;
use Mojo::Weixin::Base 'Mojo::Weixin::Model::Base';

has name => '';
has [qw(
    account
    province
    city
    sex
    id
    uid
    signature
    display
    markname
    _group_id
    _avatar
)];

sub new {
    my $self = shift;
    $self = $self->Mojo::Weixin::Base::new(@_);
    $self->client->emoji_convert(\$self->{markname},$self->client->emoji_to_text);
    $self->client->emoji_convert(\$self->{display},$self->client->emoji_to_text);
    #$self->client->emoji_convert(\$self->{name},$self->client->emoji_to_text);
    $self->uid("") if not $self->uid;
    $self;
}

sub get_avatar{
    my $self = shift;
    $self->client->get_avatar($self,@_);
}
sub displayname{
    my $self = shift;
    return $self->display || $self->markname || $self->name || '昵称未知';
}
sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$hash){
        if(exists $hash->{$_}){
            $self->client->emoji_convert(\$hash->{$_},$self->client->emoji_to_text) if $_ eq "markname";
            $self->client->emoji_convert(\$hash->{$_},$self->client->emoji_to_text) if $_ eq "display";
            if(defined $hash->{$_} and defined $self->{$_}){
                if($hash->{$_} ne $self->{$_}){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->client->emit("group_member_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->client->emit("group_member_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
            }
        }
    }
    $self;
}

sub group {
    my $self = shift;
    return scalar $self->client->search_group(id=>$self->_group_id);
}
sub make_friend{
    my $self = shift;
    $self->client->make_friend($self,@_);
}
sub set_markname {
    my $self = shift;
    $self->client->set_markname($self,@_);
}
1;

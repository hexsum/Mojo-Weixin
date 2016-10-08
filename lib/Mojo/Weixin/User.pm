package Mojo::Weixin::User;
use Mojo::Weixin::Base 'Mojo::Weixin::Model::Base';
has [qw(
    name
    account
    province
    city
    sex
    id
    signature
    display
    markname
    _avatar    
)];

sub new {
    my $self = shift;
    $self = $self->Mojo::Weixin::Base::new(@_);
    $self->client->emoji_convert(\$self->{name},$self->client->emoji_to_text);
    $self;
}
sub get_avatar{
    my $self = shift;
    $self->client->get_avatar($self,@_);
}

sub displayname {
    my $self = shift;
    return $self->display || $self->markname || $self->name;
}

sub update{
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$self){
        if(exists $hash->{$_}){
            $self->client->emoji_convert(\$hash->{$_},$self->client->emoji_to_text) if $_ eq "name";
            if(defined $hash->{$_} and defined $self->{$_}){
                if($hash->{$_} ne $self->{$_}){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->client->emit("user_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
                }
            }
            elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                my $old_property = $self->{$_};
                my $new_property = $hash->{$_};
                $self->{$_} = $hash->{$_};
                $self->client->emit("user_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
            }
        }
    }
    $self;
}
1;

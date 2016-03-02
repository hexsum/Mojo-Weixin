package Mojo::Weixin::Group::Member;
use Mojo::Weixin::Base 'Mojo::Weixin::Model::Base';
use Mojo::Weixin::Const qw(%FACE_MAP_QQ %FACE_MAP_EMOJI);

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
    _group_id
)];

sub new {
    my $self = shift;
    $self = $self->Mojo::Weixin::Base::new(@_);
    if( my @code = $self->name=~/<span class="emoji emoji([a-zA-Z0-9]+)"><\/span>/g){
        my %map = reverse %FACE_MAP_EMOJI;
        for(@code){
            my $name = $self->name;
            $name=~s/<span class="emoji emoji$_"><\/span>/exists $map{$_}?"[$map{$_}]":"[未知表情]"/eg;
            $self->name($name);
        }
    }
    $self;
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

1;

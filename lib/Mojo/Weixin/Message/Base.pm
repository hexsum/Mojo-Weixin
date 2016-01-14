package Mojo::Weixin::Message::Base;
use Mojo::Weixin::Base -base;
use Data::Dumper;
use Encode qw(decode_utf8);
use Scalar::Util qw(blessed);

sub client {
    return $Mojo::Weixin::_CLIENT;
}
sub to_json_hash{
    my $self = shift;
    my $json = {};
    for my $key (keys %$self){
        next if substr($key,0,1) eq "_";
        if($key eq "sender"){
            $json->{sender} = decode_utf8($self->sender->displayname);
        }
        elsif($key eq "receiver"){
            $json->{receiver} = decode_utf8($self->receiver->displayname);
        }
        elsif($key eq "group"){
            $json->{group} = decode_utf8($self->group->displayname);
        }
        elsif(ref $self->{$key} eq ""){
            $json->{$key} = decode_utf8($self->{$key});
        }
    }
    return $json;
}

sub dump{
    my $self = shift;
    my $clone = {};
    my $obj_name = blessed($self);
    for(keys %$self){
        if(my $n=blessed($self->{$_})){
             $clone->{$_} = "Object($n)";
        }
        elsif($_ eq "member" and ref($self->{$_}) eq "ARRAY"){
            my $member_count = @{$self->{$_}};
            $clone->{$_} = [ "$member_count of Object(${obj_name}::Member)" ];
        }
        else{
            $clone->{$_} = $self->{$_};
        }
    }
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    $self->client->print("Object($obj_name) " . Data::Dumper::Dumper($clone));
    return $self;
}
1;

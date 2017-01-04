package Mojo::Weixin::Message::Base;
use Mojo::Weixin::Base 'Mojo::EventEmitter';
use Data::Dumper;
use Mojo::Util qw();
use Scalar::Util qw(blessed);

sub client {
    return $Mojo::Weixin::_CLIENT;
}
sub is_success{
    my $self = shift;
    return $self->code == 0?1:0;
}
sub send_status{
    my $self = shift;
    my %opt = @_;
    $self->code($opt{code})->msg($opt{msg})->info($opt{info});
}
sub _parse_send_status_data {
    my $self = shift;
    my $json = shift;
    if(defined $json){
        if($json->{BaseResponse}{Ret}!=0){
            $self->send_status(
                        code=>$json->{BaseResponse}{Ret},
                        msg=>"发送失败",
                        info=>($json->{BaseResponse}{ErrMsg}||"unknown error"),
                    );
        }
        else{
            $self->send_status(code=>0,msg=>"发送成功",info=>"success");
        }
    }
    else{
        $self->send_status(code=>-1,msg=>"发送失败",info=>"unknown data");
    }
}
sub to_json_hash{
    my $self = shift;
    my $json = {};
    for my $key ( ( (keys %$self),qw(sender receiver group ) ) ){
        next if substr($key,0,1) eq "_";
        if($key eq "sender"){
            next if $self->type eq "group_notice";
            $json->{sender} = $self->sender->displayname;
            $json->{sender_account} = $self->sender->account;
            $json->{sender_uid} = $self->sender->uid;
            $json->{sender_name} = $self->sender->name;
            $json->{sender_markname} = $self->sender->markname;
        }
        elsif($key eq "receiver"){
            next if $self->type eq 'group_message' and $self->class eq 'send';
            $json->{receiver} = $self->receiver->displayname;
            $json->{receiver_account} = $self->receiver->account;
            $json->{receiver_uid} = $self->receiver->uid;
            $json->{receiver_name} = $self->receiver->name;
            $json->{receiver_markname} = $self->receiver->markname;
        }
        elsif($key eq "group"){
            next if ($self->type ne "group_message" and $self->type ne "group_notice");
            $json->{group} = $self->group->displayname;
            $json->{group_uid} = $self->group->uid;
            $json->{group_name} = $self->group->name;
        }
        elsif($key eq "media_data"){
            $json->{$key} = defined $self->{$key}?Mojo::Util::b64_encode($self->{$key}):"";
        }
        elsif($key eq 'events'){next}
        elsif(ref $self->{$key} eq ""){
            $json->{$key} = $self->{$key} || "";
        }
    }
    return $json;
}

sub is_at{
    my $self = shift;
    my $object;
    my $displayname;
    if($self->class eq "recv"){
        $object = shift || $self->receiver;
        $displayname = $object->displayname;
    }
    elsif($self->class eq "send"){
        if($self->type eq "group_message"){
            $object = shift || $self->group->me;
            $displayname = $object->displayname;
        }
        elsif($self->type=~/^friend_message$/){
            $object = shift || $self->receiver;
            $displayname = $object->displayname;
        }
    }
    return $self->content =~/\@\Q$displayname\E( |"\xe2\x80\x85"|)/;
}

sub remove_at{
    my $self = shift;
    my $object;
    my $displayname;
    if($self->class eq "recv"){
        $object = shift || $self->receiver;
        $displayname = $object->displayname;
    }
    elsif($self->class eq "send"){
        if($self->type eq "group_message"){
            $object = shift || $self->group->me;
            $displayname = $object->displayname;
        }
        elsif($self->type=~/^friend_message$/){
            $object = shift || $self->receiver;
            $displayname = $object->displayname;
        }
    }
    my $content = $self->content;
    $content=~s/\@\Q$displayname\E( |"\xe2\x80\x85"|)//g;
    $self->content($content);
    return $self;
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
        elsif($_ eq 'media_data'){
            $clone->{$_} = '[binary data not shown]';
        }
        elsif($_ eq 'events'){
            next;
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

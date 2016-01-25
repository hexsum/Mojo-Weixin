package Mojo::Weixin::Message;
use Mojo::Weixin::Base 'Mojo::Weixin::Message::Base';
use Mojo::Weixin::Friend;
use Mojo::Weixin::Group;
use Mojo::Weixin::Group::Member;

has time => sub{time};
has ttl => 5;
has source => 'local';
has 'cb';
has from => 'none';
has allow_plugin => 1;
has [qw(sender_id receiver_id group_id content type id class format)];

sub _default_friend{Mojo::Weixin::Friend->new(@_);}
sub _defaut_group{Mojo::Weixin::Group->new(@_)}
sub _default_group_member{Mojo::Weixin::Group::Member->new(@_)}

sub sender{
    my $s = shift;
    return if not defined $s->sender_id;
    if($s->type eq "friend_message"){
        return $s->client->user if $s->class eq "send";
        return $s->client->search_friend(id=>$s->sender_id,_check_remote=>0) || _default_friend(id=>$s->sender_id) ;
    }
    elsif($s->type eq "group_message"){
        my $group = $s->client->search_group(id=>$s->group_id,_check_remote=>0);
        return _default_group_member(id=>$s->sender_id) if not defined $group;
        return $group->me if $s->class eq "send";
        return $group->search_group_member(id=>$s->sender_id,_check_remote=>0) || _default_group_member(id=>$s->sender_id);
    }
    return;
}
sub receiver {
    my $s = shift;
    return if not defined $s->receiver_id;
    if($s->type eq "friend_message"){
        return $s->client->user if $s->class eq "recv";
        return $s->client->search_friend(id=>$s->receiver_id,_check_remote=>0) || _default_friend(id=>$s->receiver_id);
    }
    elsif($s->type eq "group_message"){
        my $group = $s->client->search_group(id=>$s->group_id,_check_remote=>0);
        return _default_group_member(id=>$s->receiver_id) if not defined $group;
        return $group->me if $s->class eq "recv";
        return $group->search_group_member(id=>$s->receiver_id,_check_remote=>0) || _default_group_member(id=>$s->receiver_id);
    }
    return;
}
sub group{
    my $s =  shift;
    return if not defined $s->group_id;
    return if $s->type ne "group_message";
    return $s->client->search_group(id=>$s->group_id,_check_remote=>0) || _defaut_group(id=>$s->group_id);
}

sub  reply{
    my $s = shift;
    $s->client->reply_message($s,@_);
}
1;

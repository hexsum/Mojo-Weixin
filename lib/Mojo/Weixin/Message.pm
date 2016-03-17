package Mojo::Weixin::Message;
use Mojo::Weixin::Base 'Mojo::Weixin::Message::Base';
use Mojo::Weixin::Friend;
use Mojo::Weixin::Group;
use Mojo::Weixin::Group::Member;
use Mojo::Weixin::Const qw(%FACE_MAP_QQ %FACE_MAP_EMOJI);

has time => sub{time};
has ttl => 5;
has source => 'local';
has 'cb';
has from => 'none';
has allow_plugin => 1;
has [qw(sender_id receiver_id group_id content type id class format)];
has [qw(media_id media_mime media_name media_size media_data media_mtime media_ext media_path)];

sub new {
    my $s = shift;
    $s = $s->Mojo::Weixin::Base::new(@_);
    if(defined $s->{content} and  my @code = $s->{content}=~/<span class="emoji emoji([a-zA-Z0-9]+)"><\/span>/g){
        my %map = reverse %FACE_MAP_EMOJI;
        for(@code){
            $s->{content}=~s/<span class="emoji emoji$_"><\/span>/exists $map{$_}?"[$map{$_}]":"[未知表情]"/eg
        }
    }
    $s->{content}=~s/<br\/>/\n/g if defined $s->{content};
    $s;
}

sub _default_friend{Mojo::Weixin::Friend->new(@_);}
sub _defaut_group{Mojo::Weixin::Group->new(@_)}
sub _default_group_member{Mojo::Weixin::Group::Member->new(@_)}

sub sender{
    my $s = shift;
    return if not defined $s->sender_id;
    if($s->type eq "friend_message"){
        return $s->client->user if $s->class eq "send";
        return $s->client->search_friend(id=>$s->sender_id,_check_remote=>1) || _default_friend(id=>$s->sender_id) ;
    }
    elsif($s->type eq "group_message"){
        my $group = $s->client->search_group(id=>$s->group_id,_check_remote=>1);
        return _default_group_member(id=>$s->sender_id) if not defined $group;
        return $group->me if $s->class eq "send";
        return $group->search_group_member(id=>$s->sender_id,_check_remote=>1) || _default_group_member(id=>$s->sender_id);
    }
    return;
}
sub receiver {
    my $s = shift;
    return if not defined $s->receiver_id;
    if($s->type eq "friend_message"){
        return $s->client->user if $s->class eq "recv";
        return $s->client->search_friend(id=>$s->receiver_id,_check_remote=>1) || _default_friend(id=>$s->receiver_id);
    }
    elsif($s->type eq "group_message"){
        my $group = $s->client->search_group(id=>$s->group_id,_check_remote=>1);
        return _default_group_member(id=>$s->receiver_id) if not defined $group;
        return $group->me if $s->class eq "recv";
        return $group->search_group_member(id=>$s->receiver_id,_check_remote=>1) || _default_group_member(id=>$s->receiver_id);
    }
    return;
}
sub group{
    my $s =  shift;
    return if not defined $s->group_id;
    return if $s->type ne "group_message";
    return $s->client->search_group(id=>$s->group_id,_check_remote=>1) || _defaut_group(id=>$s->group_id);
}

sub  reply{
    my $s = shift;
    $s->client->reply_message($s,@_);
}

1;

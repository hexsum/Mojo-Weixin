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
has [qw( media_id media_type media_code media_mime media_name media_size media_data media_mtime media_ext media_path)];
has data => undef;

sub new {
    my $s = shift;
    $s = $s->Mojo::Weixin::Base::new(@_);
    if(defined $s->{content}){
        if($s->client->emoji_to_text){
            my %map = reverse %FACE_MAP_EMOJI;
            $s->{content}=~s/<span class="emoji emoji([a-zA-Z0-9]+)"><\/span>/exists $map{$1}?"[$map{$1}]":"[未知表情]"/eg 
        }
        else{
            $s->{content}=~s/<span class="emoji emoji([a-zA-Z0-9]+)"><\/span>/$s->client->encode_utf8(chr(hex($1)))/ge;
        }
        $s->{content}=~s/<br\/>/\n/g;
    }
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
    elsif($s->type eq "group_notice"){
        my $s->client->search_group(id=>$s->group_id,_check_remote=>1) || _defaut_group(id=>$s->group_id);
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
    elsif($s->type eq "group_notice"){
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
    return if ($s->type ne "group_message" and $s->type ne "group_notice");
    return $s->client->search_group(id=>$s->group_id,_check_remote=>1) || _defaut_group(id=>$s->group_id);
}

sub reply{
    my $s = shift;
    return if $s->type eq "group_notice";
    $s->client->reply_message($s,@_);
}

sub reply_media {
    my $s = shift;
    return if $s->type eq "group_notice";
    $s->client->reply_media_message($s,@_);
}

1;

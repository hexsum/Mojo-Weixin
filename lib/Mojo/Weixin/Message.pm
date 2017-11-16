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
has 'id'; #发送消息成功后，服务端返回的id，可以用于撤回消息的标识
has 'uid';#消息的本地唯一标识，客户端创建消息时生成，失败多次重试时，服务端对相同uid的消息会避免对方收到多条重复
has [qw( sender_id receiver_id group_id content type class format)];
has [qw( media_id media_type media_code media_mime media_name media_size media_data media_mtime media_ext media_path)];
has [qw( app_id app_title app_url app_name app_desc)];
has [qw( card_id card_name card_province card_city card_account card_avatar card_sex)];
has [qw( revoke_id )];
has [qw(code msg info)];
has media_chunks   => undef;  #分片上传数量，只有1片的情况下不会采用分片上传，会直接上传
has media_chunk    => 0;  #当前已经上传的分片数量
has media_clientid => undef;
has 'media_md5';
has data => undef;

sub new {
    my $s = shift;
    $s = $s->Mojo::Weixin::Base::new(@_);
    $s->client->emoji_convert($s->{content},$s->client->emoji_to_text);
    if(defined $s->{content}){
        $s->client->emoji_convert(\$s->{content},$s->client->emoji_to_text);
        $s->{content}=~s/<br\/>/\n/g;
        $s->{content}=~s/(\@.*?)\xe2\x80\x85/$1 /g;
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

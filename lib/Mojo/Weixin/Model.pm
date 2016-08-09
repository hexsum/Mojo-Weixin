package Mojo::Weixin::Model;
use strict;
use base qw(Mojo::Weixin::Model::Base);
use List::Util qw(first);
use Mojo::Weixin::Model::Remote::_webwxinit;
use Mojo::Weixin::Model::Remote::_webwxgetcontact;
use Mojo::Weixin::Model::Remote::_webwxbatchgetcontact;
use Mojo::Weixin::Model::Remote::_webwxstatusnotify;
use Mojo::Weixin::Model::Remote::_webwxcreatechatroom;
use Mojo::Weixin::Model::Remote::_webwxupdatechatroom;
use Mojo::Weixin::Model::Remote::_webwxoplog;
use Mojo::Weixin::Model::Remote::_webwxverifyuser;
use Mojo::Weixin::Model::Remote::_webwxgetheadimg;
use Mojo::Weixin::User;
use Mojo::Weixin::Group;
use Mojo::Weixin::Const;

sub model_init{
    my $self = shift;
    $self->info("获取联系人信息...");
    my $initinfo = $self->_webwxinit();
    if(not defined $initinfo){
        $self->error("获取联系人信息失败");
        return; 
    }
    my($user,undef,$init_groups) = @$initinfo;
    if(defined $user){
        $self->info("更新个人信息成功");
        $self->user(Mojo::Weixin::User->new($user));
        $self->_webwxstatusnotify($self->user->id,3);
    }
    my $contactinfo = $self->_webwxgetcontact();
    if(not defined $contactinfo){
        $self->error("获取通讯录联系人信息失败");
        return;
    }
    my($friends,$contact_groups) = @$contactinfo;
    if(ref $friends eq "ARRAY" and @$friends>0){
        $self->friend([ map {Mojo::Weixin::Friend->new($_)} grep {$_->{id} ne $user->{id}} @$friends ]);
        $self->info("更新好友信息成功");
    }

    my %groups_id;
    if(ref $init_groups eq "ARRAY" and @$init_groups >0){
        for(@$init_groups){
            $groups_id{$_->{id}} = 1;
        }
    }
    if(ref $contact_groups eq "ARRAY" and @$contact_groups>0){
        for(@$contact_groups){
            $groups_id{$_->{id}} = 1;
        }
    }
    if(keys %groups_id){
        my $info = $self->_webwxbatchgetcontact(keys %groups_id);
        if(defined $info){
            my(undef,$groups) = @$info;
            if(ref $groups eq "ARRAY" and @$groups >0){
                $self->group([ map { Mojo::Weixin::Group->new($_) } @$groups ]);
                $self->info("更新群组[ @{[$_->displayname]} ]信息成功") for $self->groups;
            }
        }
        else{
            $self->error("更新群组信息失败");
            return;
        }
    }
    return 1;
}
sub update_user {

}
sub update_friend{
    my $self = shift;
    if(defined $_[0]){
        my $friend_id = ref $_[0] eq "Mojo::Weixin::Friend"?$_[0]->id:$_[0];
        my $info = $self->_webwxbatchgetcontact($friend_id);
        return if not defined $info;
        my ($friends) = @$info;
        $self->add_friend(Mojo::Weixin::Friend->new($friends->[0]));
        return;
    }
}
sub update_group{
    my $self = shift;
    if(defined $_[0]){
        my $group_id = ref $_[0] eq "Mojo::Weixin::Group"?$_[0]->id:$_[0];
        my $info = $self->_webwxbatchgetcontact($group_id);
        return if not defined $info;
        my(undef,$groups) = @$info;
        $self->add_group(Mojo::Weixin::Group->new($groups->[0]));
        return;
    }
}

sub search_friend{
    my $self = shift;
    my %p = @_;
    if($p{_check_remote}){
        if(wantarray){
            my @f = $self->_search($self->friend,@_);
            if(@f){return @f}
            else{
                $self->update_friend($p{id}) if defined $p{id};
                return $self->_search($self->friend,@_);
            }
        }
        else{
            my $f = $self->_search($self->friend,@_);
            if(defined $f){return $f }
            else{
                $self->update_friend($p{id}) if defined $p{id};
                return $self->_search($self->friend,@_);
            }
        }
    }
    return $self->_search($self->friend,@_);
}
sub search_group{
    my $self = shift;
    my %p = @_;
    if($p{_check_remote}){
        if(wantarray){
            my @g = $self->_search($self->group,@_);
            if(@g){return @g}
            else{
                $self->update_group($p{id}) if defined $p{id};
                return $self->_search($self->group,@_);
            }
        }
        else{
            my $g = $self->_search($self->group,@_);
            if(defined $g){return $g }
            else{
                $self->update_group($p{id}) if defined $p{id};
                return $self->_search($self->group,@_);
            }
        }
    }
    return $self->_search($self->group,@_);
}
sub add_friend{
    my $self = shift;
    my $friend = shift;
    $self->die("不支持的数据类型\n") if ref $friend ne "Mojo::Weixin::Friend";
    $self->emit(new_friend=>$friend) if $self->_add($self->friend,$friend) == 1;
}
sub remove_friend{
    my $self = shift;
    my $friend = shift;
    $self->die("不支持的数据类型\n") if ref $friend ne "Mojo::Weixin::Friend";
    $self->emit(lose_friend=>$friend) if $self->_remove($self->friend,$friend) == 1;
}
sub add_group{
    my $self = shift;
    my $group = shift;
    $self->die("不支持的数据类型\n") if ref $group ne "Mojo::Weixin::Group";
    $self->emit(new_group=>$group) if $self->_add($self->group,$group) == 1;
}
sub remove_group{
    my $self = shift;
    my $group = shift;
    $self->die("不支持的数据类型\n") if ref $group ne "Mojo::Weixin::Group";
    $self->emit(lose_group=>$group) if $self->_remove($self->group,$group) == 1;
}

sub is_group{
    my $self = shift;
    my $gid = shift;
    return index($gid,'@@')==0?1:0;
}
sub code2sex{
    my $c = shift;
    my %h = (
        0 => "",
        1 => "male",
        2 => "female",
    );
    return $h{$c} || "";
}

sub each_friend{
    my $self = shift;
    my $callback = shift;
    $self->die("参数必须是函数引用") if ref $callback ne "CODE";
    for (@{$self->friend}){
        $callback->($self,$_);
    }
}
sub each_group{
    my $self = shift;
    my $callback = shift;
    $self->die("参数必须是函数引用") if ref $callback ne "CODE";
    for (@{$self->group}){
        $callback->($self,$_);
    }
}

sub friends{
    my $self = shift;
    return @{$self->friend};
}
sub groups{
    my $self = shift;
    return @{$self->group};
}

sub set_friend_markname {
    my $self = shift;
    my $friend = shift;
    my $markname = shift;
    if(ref $friend ne "Mojo::Weixin::Friend"){
        $self->die("无效的对象数据类型");
        return;
    }
    my $displayname = $friend->displayname;
    my $ret = $self->_webwxoplog($friend->id,$markname);
    if($ret){
        $self->info("设置好友 $displayname 备注[ $markname ]成功");
        return 1;
    }
    else{
        $self->info("设置好友 $displayname 备注[ $markname ]失败");
        return 0;
    }

}

sub create_group {
    my $self = shift;
    my $friends;
    my $displayname;
    if(ref $_[0] eq "HASH"){
        my %opt = @_;
        $friends = $opt{friends};
        $displayname = $opt{displayname};
    }
    elsif(ref $_[0] eq "ARRAY"){
        $friends = $_[0];
        $displayname = $_[1];
    }
    else{
        $friends = \@_;
    } 
    my $group_info = $self->_webwxcreatechatroom($friends,$displayname);
    if(not defined $group_info){
        $self->error("创建群聊". (defined $displayname?"[ $displayname ]":"") . "失败");
        return;
    }
    my $info = $self->_webwxbatchgetcontact($group_info->{id});
    my $group;
    if(defined $info){
        my(undef,$groups)=@$info;
        if(ref $groups eq "ARRAY"){
            $group = Mojo::Weixin::Group->new($groups->[0]);
        }
        else{
            $group =Mojo::Weixin::Group->new($group_info);
        }
    }
    else{
        $group =Mojo::Weixin::Group->new($group_info);
    }
    $self->add_group($group);
    $self->info("创建群聊[ ". $group->displayname ." ]成功");
    return $group;
}

sub set_group_displayname {
    my $self = shift;
    my $group = shift;
    my $displayname  = shift;
    if(ref $group ne "Mojo::Weixin::Group"){
        $self->die("无效的对象数据类型");
        return;
    } 
    if(not $displayname){
        $self->die("无效的显示名称");
        return;
    }

    my $ret = $self->_webwxupdatechatroom("mod",$group,$displayname);
    if($ret){
        $self->info("修改群显示名称[ $displayname ]成功");
        return 1;
    }
    else{
        $self->info("修改群显示名称[ $displayname ]失败");
        return 0;
    }
}

sub invite_friend{
    my $self =shift;
    my $group = shift;
    my @friends = @_;
    for(@friends){
        $self->die("非好友对象") if not $_->is_friend;
    }
    $self->die("非群组对象") if not $group->is_group;
    my $ret = $self->_webwxupdatechatroom("add",$group,@friends);    
    if($ret){
        $self->update_group($group);
        $self->info("邀请好友 " . join("、",map {$_->displayname} grep {defined $_} @friends[0..2]) . "... 加入群[ " . $group->displayname . " ]成功");
        return 1;
    }
    else{
        $self->info("邀请好友 " . join("、",map {$_->displayname} grep {defined $_} @friends[0..2]) . "... 加入群[ " . $group->displayname . " ]失败");
        return 0;
    }
}
sub kick_group_member{
    my $self = shift;
    my $group = shift;
    my @members = @_;
    for(@members){
        $self->die("非群成员对象") if not $_->is_group_member;
    }
    $self->die("非群组对象") if not $group->is_group;
    my $ret = $self->_webwxupdatechatroom("del",$group,@members);
    if($ret){
        $group->remove_group_member($_) for @members;
        $self->info("从群组[ ". $group->displayname. " ]移除群成员 " . join("、",map {$_->displayname} grep {defined $_} @members[0..2]) . " 成功");
        return 1;
    }
    else{
        $self->info("从群组[ ". $group->displayname. " ]移除群成员 " . join("、",map {$_->displayname} grep {defined $_} @members[0..2]) . " 失败");
        return 0;
    }
}

sub make_friend{
    my $self = shift;
    my $member = shift;
    my $content = shift || '';
    $self->die("非群组成员对象") if not $member->is_group_member;
    my $ret = $self->_webwxverifyuser($member->id,$content,2,"");
    if($ret){
        $self->info("好友请求[ ". $member->displayname . " ]发送成功: "  . ($content?$content:"(验证内容为空)"));
        return 1;
    }
    else{
        $self->info("好友请求[ ". $member->displayname . " ]发送失败: " . ($content?$content:"(验证内容为空)"));
        return 0;
    }
}

sub accept_friend_request{
    my $self = shift;
    my $id = shift;
    my $displayname = shift;
    my $ticket = shift;
    my $ret = $self->_webwxverifyuser($id,"",3,$ticket);
    if($ret){
        $self->info("[ " . $displayname .  " ]的好友请求已被接受");
        return 1;
    }
    else{
        $self->info("[ " . $displayname . " ]的好友请求接受失败");
        return 0;
    }
}

sub get_avatar {
    my $self = shift;
    my $object =  shift;
    my $callback = shift;
    if(ref($object) !~ /Mojo::Weixin::User|Mojo::Weixin::Friend|Mojo::Weixin::Group|Mojo::Weixin::Groupp::Member/){
        $self->die("不支持的数据类型");
        return;
    }
    elsif(ref $callback ne "CODE"){
        $self->warn("未设置回调函数");
        return;
    }
    $self->_webwxgetheadimg($object,$callback);
}

1;

package Mojo::Weixin::Model;
use base qw(Mojo::Weixin::Model::Base);
use List::Util qw(first);
use Mojo::Weixin::Model::Remote::_webwxinit;
use Mojo::Weixin::Model::Remote::_webwxgetcontact;
use Mojo::Weixin::Model::Remote::_webwxbatchgetcontact;
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
    }

    my $contactinfo = $self->_webwxgetcontact();
    if(not defined $contactinfo){
        $self->error("获取通讯录联系人信息失败");
        return;
    }
    my($friends,$contact_groups) = @$contactinfo;
    if(ref $friends eq "ARRAY" and @$friends>0){
        for(@$friends){
            if($_->{id} eq $user->{id}){
                $self->user->update($_);
                next;
            }
            $self->add_friend(Mojo::Weixin::Friend->new($_));
        } 
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
                for(@$groups){
                    my $group = Mojo::Weixin::Group->new($_);
                    $self->add_group($group);
                    $self->info("更新群组[ @{[$group->displayname]} ]信息成功");
                }
            }
        }
        else{
            $self->error("更新群组信息失败");
        }
    }
}
sub update_user {

}
sub update_friend{

}
sub update_group{

}

sub search_friend{
    my $self = shift;
    my %p = @_;
    if($p{_check_remote}){
        if(wantarray){
            my @f = $self->_search($self->friend,@_);
            if(@f){return @f}
            else{
                $self->update_friend();
                return $self->_search($self->friend,@_);
            }
        }
        else{
            my $f = $self->_search($self->friend,@_);
            if(defined $f){return $f }
            else{
                $self->update_friend();
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
                $self->update_group();
                return $self->_search($self->group,@_);
            }
        }
        else{
            my $g = $self->_search($self->group,@_);
            if(defined $g){return $g }
            else{
                $self->update_group();
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
    return $self->_add($self->friend,$friend);   
}
sub remove_friend{
    my $self = shift;
    my $friend = shift;
    $self->die("不支持的数据类型\n") if ref $friend ne "Mojo::Weixin::Friend";
    return $self->_remove($self->friend,$friend);
}
sub add_group{
    my $self = shift;
    my $group = shift;
    $self->die("不支持的数据类型\n") if ref $group ne "Mojo::Weixin::Group";
    return $self->_add($self->group,$group);
}
sub remove_group{
    my $self = shift;
    my $group = shift;
    $self->die("不支持的数据类型\n") if ref $group ne "Mojo::Weixin::Group";
    return $self->_remove($self->group,$group);
}

sub is_group{
    my $self = shift;
    my $gid = shift;
    return index($gid,'@@')==0?1:0;
}
sub code2sex{
    my $c = shift;
    my %h = qw(
        0   none
        1   male
        2   female
    );
    return $h{$c} || "none";
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

1;

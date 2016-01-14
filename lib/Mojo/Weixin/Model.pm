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
    my($user,undef,$groups_id) = @$initinfo;
    if(defined $user){
        $self->info("更新个人信息成功");
        $self->user(Mojo::Weixin::User->new($user));
    }

    my $contactinfo = $self->_webwxgetcontact();
    if(not defined $contactinfo){
        $self->error("获取通讯录联系人信息失败");
        return;
    }
    my($friends,$incomplete_groups) = @$contactinfo;
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

    if(ref $groups_id eq "ARRAY" and @$groups_id >0){
        my $info = $self->_webwxbatchgetcontact(@$groups_id,);
        if(defined $info){
            my(undef,$groups) = @$info;
            if(ref $groups eq "ARRAY" and @$groups >0){
                for(@$groups){
                    $self->add_group(Mojo::Weixin::Group->new($_));
                    $self->info("更新普通群组[ @{[$_->{name}]} ]信息成功");
                }
            }
        }
        else{
            $self->error("更新普通群组信息失败");
        }
    }
    if(ref $incomplete_groups eq "ARRAY" and @$incomplete_groups>0){
        my $info = $self->_webwxbatchgetcontact(map{ $_->{id}} @$incomplete_groups);
        if(defined $info){
            my(undef,$groups) = @$info;
            if(ref $groups eq "ARRAY" and @$groups>0){
                for (@$groups){
                    $self->add_group(Mojo::Weixin::Group->new($_));
                    $self->info("更新通讯录群组[ @{[$_->{name}]} ]信息成功");
                }
            }
        }
        else{
            $self->error("更新通讯录群组信息失败");
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

1;

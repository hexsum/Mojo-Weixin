package Mojo::Weixin::Group;
use Mojo::Weixin::Base 'Mojo::Weixin::Model::Base';
use Mojo::Weixin::Group::Member;

has 'id';
has name => '';
has member => sub{[]};
sub displayname { 
    my $self = shift;
    return $self->name if $self->name;
    my $default_name = join "、", map { $_->displayname } grep {defined $_} (grep {$_->id ne $self->client->user->id} @{$self->member})[0..2];
    return $default_name?$default_name:"群名未知";
}
sub new {
    my $class = shift;
    my $self;
    bless $self=@_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
    if(exists $self->{member} and ref $self->{member} eq "ARRAY"){
        for( @{ $self->{member} } ){
            $_ = Mojo::Weixin::Group::Member->new($_) if ref $_ ne "Mojo::Weixin::Group::Member";
        }
    }
    $self;
}
sub is_empty{
    my $self = shift;
    return !(ref($self->member) eq "ARRAY"?0+@{$self->member}:0);
}
sub update {
    my $self = shift;
    my $hash = shift;
    for(grep {substr($_,0,1) ne "_"} keys %$self){
        if($_ eq "member" and ref $hash->{member} eq "ARRAY"){
            next if not @{$hash->{member}};
            my @member = 
            map {ref $_ eq "Mojo::Weixin::Group::Member"?$_:Mojo::Weixin::Group::Member->new($_)} 
            @{$hash->{member}};

            if( $self->is_empty() ){
                $self->member(\@member);
            }
            else{
                my($new_members,$lost_members,$sames)=$self->client->array_diff($self->member, \@member,sub{$_[0]->id});
                for(@{$new_members}){
                    $self->add_group_member($_);
                    $self->client->emit(new_group_member=>$_) if defined $self->client;
                }
                for(@{$lost_members}){
                    $self->remove_group_member($_);
                    $self->client->emit(lose_group_member=>$_) if defined $self->client;
                }
                for(@{$sames}){
                    my($old_member,$new_member) = ($_->[0],$_->[1]);
                    $old_member->update($new_member);
                }
            }
        }
        else{
            if(exists $hash->{$_}){
                if(defined $hash->{$_} and defined $self->{$_}){
                    if($hash->{$_} ne $self->{$_}){
                        my $old_property = $self->{$_};
                        my $new_property = $hash->{$_};
                        $self->{$_} = $hash->{$_};
                        $self->client->emit("group_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
                    }
                }
                elsif( ! (!defined $hash->{$_} and !defined $self->{$_}) ){
                    my $old_property = $self->{$_};
                    my $new_property = $hash->{$_};
                    $self->{$_} = $hash->{$_};
                    $self->client->emit("group_property_change"=>$self,$_,$old_property,$new_property) if defined $self->client;
                }
            }
        }
    }
    $self;
}

sub search_group_member{
   my $self = shift;
    my %p = @_;
    if($p{_check_remote}){
        if(wantarray){
            my @g = $self->_search($self->member,@_);
            if(@g){return @g}
            else{
                $self->update_group($self);
                return $self->_search($self->member,@_);
            }
        }
        else{
            my $g = $self->_search($self->member,@_);
            if(defined $g){return $g }
            else{
                $self->update_group($self);
                return $self->_search($self->member,@_);
            }
        }
    }
    return $self->_search($self->member,@_);
}
sub add_group_member{
    my $self = shift;
    my $member = shift;
    $self->client->die("不支持的数据类型\n") if ref $member ne "Mojo::Weixin::Group::Member";
    return $self->_add($self->member,$member);
}
sub remove_group_member{
    my $self = shift;
    my $member = shift;
    $self->client->die("不支持的数据类型\n") if ref $member ne "Mojo::Weixin::Group::Member";
    return $self->_remove($self->member,$member);
}

sub me {
    my $self = shift;
    return $self->search_group_member(id=>$self->client->user->id);
}
sub send{
    my $self = shift;
    $self->client->send_message($self,@_);
}

1;

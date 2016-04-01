package Mojo::Weixin::Cache;
sub new{
    return bless {}
}
sub all {
    my $self = shift;
    my @res;
    for (keys %$self){
        if($self->{$_}{ctime}+$self->{$_}{ttl} <= time){push @res,{key=>$_,data=>$self->{$_}{data}}}
        else{$self->delete($_)}
    }
    return wantarray?@res:\@res;
}
sub count {
    my $self = shift;
    my $count = 0;
    for (keys %$self){
        if($self->{$_}{ctime}+$self->{$_}{ttl} <= time){$count++}
        else{$self->delete($_)}
    }
    return $count;
}
sub store {
    my $self= shift;
    my ($data_key,$data,$ttl) = @_; 
    $self->{$data_key}{data} = $data;
    $self->{$data_key}{ttl} = $ttl;
    $self->{$data_key}{ctime} = time;
    
}
sub delete {
    my $self= shift;
    my $data_key = shift;
    delete $self->{$data_key};
}
sub retrieve{
    my $self = shift;
    my $data_key = shift;
    if(exists $self->{$data_key} ){
        if(defined $self->{$data_key}{ttl}){
            if($self->{$data_key}{ttl} + $self->{$data_key}{ctime} > time){
                return $self->{$data_key}{data};
            }
            else{delete $self->{$data_key};return undef}
        }
        else{
           return $self->{$data_key}{data}; 
        }
    }
    else{return undef}
}
1;

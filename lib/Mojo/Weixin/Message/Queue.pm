package Mojo::Weixin::Message::Queue;
sub new {
    my $class  = shift;
    my %p = @_;
    my $self = {
        queue               =>  [],
        callback_for_get    =>  undef,
        callback_for_get_bak   =>  undef,
    };
    if(ref $p{callback_for_get} eq "CODE"){
        $self->{callback_for_get}  = $p{callback_for_get};
        $self->{callback_for_get_bak} = $self->{callback_for_get}; 
    }
    return bless $self,$class;
}
sub put {
    my $self = shift;
    die "Mojo::Weixin::Message::Queue->put()失败，请检查是否已经设置了队列get()回调\n"
        unless ref $self->{callback_for_get} eq 'CODE';    
    push @{ $self->{queue} } ,$_[0];
    $self->_notify_to_get();
}
sub get {
    my $self = shift;
    my $cb = shift;
    if(defined $cb){
        die "Mojo::Weixin::Message::Queue->get()仅接受一个函数引用\n" unless ref $cb eq 'CODE';
        $self->{callback_for_get} = $cb;
        $self->{callback_for_get_bak} = $cb;
    }
}
sub _notify_to_get{
    my $self = shift;
    my $msg = shift @{$self->{queue}};
    $self->{callback_for_get}->($msg);
}
1;

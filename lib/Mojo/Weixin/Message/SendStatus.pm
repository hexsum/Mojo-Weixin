package Mojo::Weixin::Message::SendStatus;
use Mojo::Weixin::Base 'Mojo::Weixin::Message::Base';
has [qw(code msg info)];
sub is_success{
    my $self = shift;
    return $self->code == 0?1:0;
}
1;

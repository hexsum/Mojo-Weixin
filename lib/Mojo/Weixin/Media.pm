package Mojo::Weixin::Media;
use Mojo::Weixin:Base -base;
has [qw(
    size
    mtime
    data
    mime
    name
)];
1;

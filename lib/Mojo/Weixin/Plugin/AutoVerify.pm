package Mojo::Weixin::Plugin::AutoVerify;
our $PRIORITY = 1;
sub call {
    my $client = shift;
    my $data  = shift;
    $client->on(friend_request=>sub{
        my($client,$id,$displayname,$verify,$ticket) = @_;
        $client->accept_friend_request($id,$displayname,$ticket);
    }); 
}
1;

use strict;
use File::Temp qw/:seekable/;
use Mojo::Util ();
sub Mojo::Weixin::_get_media {
    my $self = shift;
    my $media_id = shift; 
    my $callback = shift;
    my $type = shift;
    my $api = 'https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxgetmsgimg';
    my @query_string = (
        '' => '',
        MsgID => $media_id,
        skey  => Mojo::Util::url_escape($self->skey),
    );
    push @query_string,(type => "slave") if $type;
    $self->http_get($self->gen_url($api,@query_string), {Referer=>'https' . $self->domain .'/'},sub{
        my ($data,$ua,$tx) = @_;
        return if not defined $data;
        unless(defined $data){
            $self->warn("media下载失败: " . $tx->error->{message});
            return;
        }
        my $mime = $tx->res->headers->content_type;
        my $type =      $mime=~/^image\/jpe?g/i        ?   ".jpg"
                    :   $mime=~/^image\/png/i          ?   ".png"
                    :   $mime=~/^image\/bmp/i          ?   ".bmp"
                    :   $mime=~/^image\/gif/i          ?   ".gif"
                    :   $mime=~/^text\/plain/i         ?   ".txt"
                    :   $mime=~/^text\/html/i          ?   ".html"
                    :   $mime=~/^text\/json/i          ?   ".json"
                    :   $mime=~/^application\/json/i   ?   ".json"
                    :                           ".dat"
        ; 
        return unless defined $type;
        if(defined $self->media_dir and not -d $self->media_dir){
            $self->error("无效的 media_dir: " . $self->media_dir);
            return;
        }
        my @opt = (
            TEMPLATE    => "mojo_weixin_media_XXXX",
            SUFFIX      => $type,
            UNLINK      => 0,
        );
        defined $self->media_dir?(push @opt,(DIR=>$self->media_dir)):(push @opt,(TMPDIR=>1));
        eval{
            my $tmp = File::Temp->new(@opt);
            binmode $tmp;
            print $tmp $data;
            close $tmp;
            $callback->($tmp->filename,$data,) if ref $callback eq "CODE";
        };
        $self->error("[ ". __PACKAGE__ . " ] $@") if $@;
    });
}
1;

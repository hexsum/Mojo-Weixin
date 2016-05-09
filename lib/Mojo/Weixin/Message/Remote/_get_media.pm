use strict;
use File::Temp qw/:seekable/;
use Mojo::Util ();
use File::Basename qw(basename);
sub Mojo::Weixin::_get_media {
    my $self = shift;
    my $msg = shift;
    my $callback = shift;
    my $type = shift;

    my $media_id = $msg->media_id; 
    my $api = 'https://wx.qq.com/cgi-bin/mmwebwx-bin/webwxgetmsgimg';
    my @query_string = (
        '' => '',
        MsgID => $media_id,
        skey  => Mojo::Util::url_escape($self->skey),
    );
    push @query_string,(type => "slave") if $type;
    $self->http_get($self->gen_url($api,@query_string), {Referer=>'https' . $self->domain .'/'},sub{
        my ($data,$ua,$tx) = @_;
        if(not defined $data){
            $self->warn("media[ " . $msg->media_id . " ]下载失败");
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
        $msg->media_mime($mime);
        $msg->media_ext(substr($type,1));
        $msg->media_data($data);
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
            $msg->media_path($tmp->filename);
            $msg->media_name(basename($msg->media_path));
            $msg->media_mtime(time);
            $msg->media_size(length($data));
            $callback->($tmp->filename,$data,$msg) if ref $callback eq "CODE";
        };
        $self->die("[ ". __PACKAGE__ . " ] $@") if $@;
    });
}
1;

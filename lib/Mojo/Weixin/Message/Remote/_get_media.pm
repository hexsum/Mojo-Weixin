use strict;
use File::Temp qw/:seekable/;
use Mojo::Util ();
use File::Basename ();
sub Mojo::Weixin::_get_media {
    my $self = shift;
    my $msg = shift;
    my $callback = shift;

    my $media_id = (split ":",$msg->media_id)[0]; 
    my $api;
    my @query_string;
    my $headers = {};
    if($msg->media_type eq "image"){
        $api = 'https://'.$self->domain . '/cgi-bin/mmwebwx-bin/webwxgetmsgimg';
        @query_string = ('' => '',MsgID => $media_id,);
        push @query_string,(skey=>Mojo::Util::url_escape($self->skey)) if $self->skey;
    }
    elsif($msg->media_type eq "voice"){
        $api = 'https://'.$self->domain . '/cgi-bin/mmwebwx-bin/webwxgetvoice';
        @query_string = (msgid=>$media_id);
        push @query_string,(skey=>Mojo::Util::url_escape($self->skey)) if $self->skey;
    }
    elsif($msg->media_type eq "video" or $msg->media_type eq "microvideo"){
        $api = 'https://'.$self->domain . '/cgi-bin/mmwebwx-bin/webwxgetvideo';
        @query_string = (msgid=>$media_id);
        push @query_string,(skey=>Mojo::Util::url_escape($self->skey)) if $self->skey;
        $headers = {Range => 'bytes=0-'};
    }
    elsif($msg->media_type eq "emoticon"){
        $api = 'https://'.$self->domain . '/cgi-bin/mmwebwx-bin/webwxgetmsgimg';
        @query_string = ('' => '',MsgID => $media_id,type=>'big');
        push @query_string,(skey=>Mojo::Util::url_escape($self->skey)) if $self->skey;
    }
    else{
        $self->error("获取media错误：不支持的media类型");
        return;
    }
    $self->http_get($self->gen_url($api,@query_string),$headers, {Referer=>'https://' . $self->domain .'/'},sub{
        my ($data,$ua,$tx) = @_;
        if(not defined $data){
            $self->warn("media[ " . $msg->media_id . " ]下载失败");
            return;
        }
        my $mime = $data=~/^GIF8/?"image/gif":$tx->res->headers->content_type;
        my $type =      $mime=~/^image\/jpe?g/i        ?   "jpg"
                    :   $mime=~/^image\/png/i          ?   "png"
                    :   $mime=~/^image\/bmp/i          ?   "bmp"
                    :   $mime=~/^image\/gif/i          ?   "gif"
                    :   $mime=~/^text\/plain/i         ?   "txt"
                    :   $mime=~/^text\/html/i          ?   "html"
                    :   $mime=~/^text\/json/i          ?   "json"
                    :   $mime=~/^application\/json/i   ?   "json"
                    :   $mime=~/^video\/mp4/i          ?   "mp4"
                    :   $mime=~/^audio\/mp3/i          ?   "mp3"
                    :   $mime=~/^audio\/mpeg/i         ?   "mp3"
                    :   $mime=~/^application\/json/i   ?   "json"
                    :                                      "dat"
        ; 
        return unless defined $type;
        $mime=~s/\s*;.*$//g;
        $msg->media_mime($mime);
        $msg->media_ext($type);
        $msg->media_data($data);
        $msg->media_mtime(time);
        $msg->media_size(length($data));

        if($msg->media_size == 0){
            $msg->media_path("non-exist-path") if $msg->media_size == 0;
            $msg->media_name(File::Basename::basename($msg->media_path));
            $callback->($msg->media_path,$data,$msg) if ref $callback eq "CODE";
            return;
        }
        if(defined $self->media_dir and not -d $self->media_dir){
            $self->error("无效的 media_dir: " . $self->media_dir);
            return;
        }
        my @opt = (
            TEMPLATE    => "mojo_weixin_media_XXXX",
            SUFFIX      => ".$type",
            UNLINK      => 0,
        );
        defined $self->media_dir?(push @opt,(DIR=>$self->media_dir)):(push @opt,(TMPDIR=>1));
        eval{
            my $tmp = File::Temp->new(@opt);
            binmode $tmp;
            print $tmp $data;
            close $tmp;
            $msg->media_path($tmp->filename);
            $callback->($tmp->filename,$data,$msg) if ref $callback eq "CODE";
        };
        $self->error("[ ". __PACKAGE__ . " ] $@") if $@;
    });
}
1;

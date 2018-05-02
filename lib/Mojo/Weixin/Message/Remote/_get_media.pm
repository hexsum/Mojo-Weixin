use strict;
use File::Temp qw/:seekable/;
use Mojo::Util ();
use File::Basename ();
use File::Spec ();
use Encode ();
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
    elsif($msg->media_type eq "file"){
        $api = 'https://file.' . $self->domain . '/cgi-bin/mmwebwx-bin/webwxgetmedia';
        @query_string = (
            sender=>$msg->sender_id,
            mediaid=>$media_id,
            filename=>$msg->media_name,
            fromuser=>$self->wxuin,
            pass_ticket=>($self->pass_ticket || 'undefined'),
            webwx_data_ticket=>$self->search_cookie("webwx_data_ticket")
        );
        #push @query_string,(skey=>Mojo::Util::url_escape($self->skey)) if $self->skey;
    }
    else{
        $self->error("获取media错误：不支持的media类型");
        return;
    }
    $self->http_get($self->gen_url($api,@query_string), {Referer=>'https://' . $self->domain .'/'},sub{
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
        if($msg->format eq 'media' and $msg->media_type eq 'file'){
            if($msg->media_name =~ /^.+?\.([^\.]+)$/ ){
                if($1){
                    $msg->media_ext($1);
                    #$msg->media_mime("application/octet-stream"); #txt文件这样设置mime不合理
                }
            }
        }
        $msg->media_mime($mime) if not defined $msg->media_mime;
        $msg->media_ext($type) if not defined $msg->media_ext;
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
        if($msg->media_type eq 'file'){
            my $media_name = $msg->media_name;
            my $media_dir = $self->media_dir // $self->tmpdir;

            if($^O eq 'MSWin32'){
                $media_name = Encode::encode("gbk",Encode::decode("utf8",$media_name));
                $media_dir = Encode::encode("gbk",Encode::decode("utf8",$media_dir));
            }
            my $path = File::Spec->catfile($media_dir,$media_name);
            my $i = 1;
            while( -f $path){
                if($i>100){#防止死循环
                    my $time = int(time);
                    $path =~ s/(\(\d\)|)(?=\.[^\.]+$|$)/($time)/;
                    last;
                }
                $path =~ s/(\(\d\)|)(?=\.[^\.]+$|$)/($i)/;
                $i++;
            }
            eval{
                open(my $fh,">",$path) or die $!;
                chmod 0644, $fh if $^O ne 'MSWin32';
                print $fh $data;
                close $fh;
                $msg->media_path($^O eq 'MSWin32'?Encode::encode("utf8",Encode::decode("gbk",$path)):$path);
                $callback->($path,$data,$msg) if ref $callback eq "CODE";
            };
            $self->error("[ ". __PACKAGE__ . " ] $@") if $@;
            
        }
        else{
            my $t = POSIX::strftime('%Y%m%d%H%M%S',localtime());
            my @opt = (
                TEMPLATE    => "mojo_weixin_media_${t}_XXXX",
                SUFFIX      => "." . $msg->media_ext,
                UNLINK      => 0,
            );
            defined $self->media_dir?(push @opt,(DIR=>$self->media_dir)):(push @opt,(TMPDIR=>1));
            eval{
                my $tmp = File::Temp->new(@opt);
                binmode $tmp;
                chmod 0644, $tmp if $^O ne 'MSWin32';
                print $tmp $data;
                close $tmp;
                $msg->media_path($tmp->filename);
                $callback->($tmp->filename,$data,$msg) if ref $callback eq "CODE";
            };
            $self->error("[ ". __PACKAGE__ . " ] $@") if $@;
        }
    });
}
1;

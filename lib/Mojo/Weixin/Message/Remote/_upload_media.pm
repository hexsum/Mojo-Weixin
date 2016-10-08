use strict;
use File::Temp;
use File::Basename ();
use Mojo::Util ();
use POSIX ();
use Mojo::Weixin::Const qw();
sub Mojo::Weixin::_upload_media {
    my $self = shift;
    my $msg = shift; 
    my $callback = shift;
    if(!defined $msg or (!defined $msg->media_data and !defined $msg->media_path)){
        $self->error("无效的media");
        return;
    }
    $self->steps(
    sub{
        my $delay = shift;
        my $end = $delay->begin(0,);
        if(defined $msg->media_data){
            my $r = sub{my $r = sprintf "%.3f", rand();$r=~s/\.//g;return $self->now() . $r;}->();
            $msg->media_ext("dat") if not defined $msg->media_ext;
            $msg->media_name($r . "." . $msg->media_ext) if not defined $msg->media_name;
            $msg->media_path($msg->media_name) if not defined $msg->media_path;
            $msg->media_size(length($msg->media_data)) if not defined $msg->media_size;
            $msg->media_mime('application/octet-stream') if not defined $msg->media_mime;
            $msg->media_mtime(time) if not defined $msg->media_mtime;
            $end->($msg);
            return;
        }
        elsif($msg->media_path=~/^https?:\/\/.*?([^\/]+)$/){
            my $name = $1;
            my $ext = '';
            $ext = $1 if $name =~ /\.([^\.]+)$/;
            $self->http_get($msg->media_path,sub{
                my($body,$ua,$tx) = @_; 
                return if not defined $body;
                my($mtime,$mime,$size) = ($tx->res->headers->last_modified || time, $tx->res->headers->content_type|| 'application/octet-stream',$tx->res->headers->content_length || length($body));
                $mime=~s/;.*$//;
                if(not $ext){
                    $ext =          $mime=~/^image\/jpe?g/i        ?   "jpg"
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
                 }

                $msg->media_name($name) if not defined $msg->media_name;
                $msg->media_size($size) if not defined $msg->media_size;
                $msg->media_mime($mime) if not defined $msg->media_mime;
                $msg->media_mtime($mtime) if not defined $msg->media_mtime;
                $msg->media_data($body) if not defined $msg->media_data;
                $msg->media_ext($ext) if not defined $msg->media_ext;
                $end->($msg);
            });
            return;
        }
        else{
            if(not -f $msg->media_path){
                $self->error("无效的文件路径");
                return;
            }
            my %mime_map = (
                jpeg    => 'image/jpeg',
                jpg     => 'image/jpeg',
                gif     => 'image/gif',
                bmp     => 'image/bmp',
                png     => 'image/png',
                mp3     => 'audio/mp3',
                mp4     => 'video/mp4',
            );
            my $mime_reg = join "|",keys %mime_map;
            eval{
                my $data = Mojo::Util::slurp $msg->media_path;
                my $name = File::Basename::basename($msg->media_path);
                my $mtime = (stat($msg->media_path))[9];
                my $size = length($data);
                my $mime = 'application/octet-stream';
                if($name=~/\.($mime_reg)$/) {
                    $mime = $mime_map{$1};
                }
                my $ext = '';
                $ext = $1 if $name =~ /\.([^\.]+)$/;
                $ext = 'dat' if not $ext;

                $msg->media_name($name) if not defined $msg->media_name;
                $msg->media_size($size) if not defined $msg->media_size;
                $msg->media_mime($mime) if not defined $msg->media_mime;
                $msg->media_mtime($mtime) if not defined $msg->media_mtime;
                $msg->media_data($data) if not defined $msg->media_data;  
                $msg->media_ext($ext) if not defined $msg->media_ext;  
                $end->($msg);
            };
            if($@){$self->error("读取媒体文件" .$msg->media_path . "错误： $@");return}
        }
    },
    sub {
        my $delay = shift;
        my $msg = shift;
        my $uploadmediarequest = {
            BaseRequest =>  {
                DeviceID    => $self->deviceid,
                Sid         => $self->wxsid,
                Skey        => $self->skey,
                Uin         => $self->wxuin,
            },
            ClientMediaId => sub{my $r = sprintf "%.3f", rand();$r=~s/\.//g;return $self->now() . $r;}->(),
            TotalLen  => $msg->media_size,
            StartPos  => 0,
            DataLen   => $msg->media_size,
            MediaType => 4,
        };

        if(not defined $msg->media_type){
            my $media_type = $msg->media_mime=~/^image\/gif/i         ?   "emoticon"
                        :    $msg->media_mime=~/^video\/mp4/i         ?   "video"
            #           :    $msg->media_mime=~/^audio\/mp3/i         ?   "voice"
                        :    $msg->media_mime=~/^image\//             ?   "image"
                        :                                                 "file"
            ;
            $msg->media_type($media_type);
        }
        $msg->media_code($Mojo::Weixin::Const::KEY_MAP_MEDIA_CODE{$msg->media_type} || 6);
        my $msg_content =   $msg->media_type eq "image"     ?  "[图片]"
                        :   $msg->media_type eq "emoticon"  ?  "[表情]"
                        :   $msg->media_type eq "video"     ?  "[视频]"
                        :   $msg->media_type eq "microvideo"?  "[小视频]"
                        :   $msg->media_type eq "voicce"    ?  "[语音]"
                        :   $msg->media_type eq "file"      ?  "[文件]"
                        :   "[文件]"
        ;
        $msg->content($msg_content . "(" . $msg->media_path . ")");

        $self->http_post(
            'https://file.' . $self->domain .'/cgi-bin/mmwebwx-bin/webwxuploadmedia?f=json',
            {json=>1,Referer=>'https://' . $self->domain . '/'},
            form=>{
                id=>'WU_FILE_0',
                name=>$msg->media_name,
                type=>$msg->media_mime,
                lastModifiedDate=>POSIX::strftime('%a, %d %b %Y %H:%M:%S GMT+0800',gmtime($msg->media_mtime)),
                size=>$msg->media_size,
                mediatype=>(
                        $msg->media_type eq "image"                                             ?   "pic"
                    :   ($msg->media_type eq "video" or $msg->media_type eq "microvideo")       ?   "video"
                    :                                                                               "doc"
                ),
                uploadmediarequest=>$self->encode_json($uploadmediarequest),
                webwx_data_ticket=>$self->search_cookie("webwx_data_ticket"),
                pass_ticket => $self->pass_ticket,
                filename =>{
                    content=>$msg->media_data,
                    filename=>$msg->media_name,
                    'Content-Type' => $msg->media_mime,
                },
            },
            sub{
                my $json = shift;
                if(not defined $json){
                    $self->warn("media [ ".$msg->media_path . " ] upload failure");
                }
                else{
                    $msg->media_id($json->{MediaId}) if $json->{MediaId};
                }
                $callback->($msg,$json);
            }
        );
    }
    );
}
1;

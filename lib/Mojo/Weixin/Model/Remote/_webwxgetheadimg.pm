use strict;
use File::Temp qw/:seekable/;
sub Mojo::Weixin::_webwxgetheadimg {
    my $self = shift;
    my $object = shift;
    my $callback = shift;
    if(not $object->_avatar){
        $self->warn("对象[ " . $object->displayname . " ]头像地址无效");
        return;
    }
    my $url = 'https://' . $self->domain . $object->_avatar;
    $self->http_get($url,{Referer=>'https://' . $self->domain .'/'},sub{
        my ($data,$ua,$tx) = @_;
        if(not defined $data){
            $self->warn("获取对象[ " . $object->displayname . " ]头像失败: 数据无效");
            return;
        }
        my $mime =  $data=~/^GIF8/          ?   'image/gif'
                :   $data=~/^PNG|\x89PNG/   ?   'image/png'
                :                               $tx->res->headers->content_type
        ;
        $mime=~s/;.*$//;
        my $type =      $mime=~/^image\/jpe?g/i        ?   ".jpg"
                    :   $mime=~/^image\/png/i          ?   ".png"
                    :   $mime=~/^image\/bmp/i          ?   ".bmp"
                    :   $mime=~/^image\/gif/i          ?   ".gif"
                    :                                      undef
        ; 
        if(not defined $type){
            $self->warn("获取对象[ " . $object->displayname . " ]头像失败: 非图像类型数据");
            return;
        }
        if(defined $self->media_dir and not -d $self->media_dir){
            $self->error("无效的 media_dir: " . $self->media_dir);
            return;
        }
        my @opt = (
            TEMPLATE    => "mojo_weixin_avatar_XXXX",
            SUFFIX      => $type,
            UNLINK      => 0,
        );
        defined $self->media_dir?(push @opt,(DIR=>$self->media_dir)):(push @opt,(TMPDIR=>1));
        eval{
            my $tmp = File::Temp->new(@opt);
            binmode $tmp;
            print $tmp $data;
            close $tmp;
            $self->debug("获取对象[ " . $object->displayname . " ]头像成功: " . $tmp->filename);
            $callback->($tmp->filename,$data,$mime) if ref $callback eq "CODE";
        };
        $self->error("[ ". __PACKAGE__ . " ] $@") if $@;
    });
}
1;

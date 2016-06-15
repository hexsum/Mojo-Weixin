package Mojo::Weixin::Plugin::ImageStore;
our $PRIORITY = 100;
use POSIX qw(strftime);
use File::Path qw(make_path);
use Mojo::Util qw(spurt);
use File::Basename qw(basename);
sub call{
    my $client = shift;
    my $data   = shift;
    my $callback = sub{
        my($client,$path,$bin,$msg) = @_;
        my $date = strftime("%Y-%m-%d",localtime($msg->time));
        my $dir = ($data->{media_dir} || $client->media_dir);
        $dir=~s/\/$//; 
        $dir .= "/" . $date;
        eval{
            make_path($dir);
            my $filename = strftime("%Y%m%d%H%M%S",localtime($msg->time));
            my $file_path = "$dir/$filename" . "." . $msg->media_ext;
            while(-f $file_path){
                if($file_path =~ /\.(\d+)\.[^\.]+$/){
                    my $n = $1+1;
                    $file_path =~ s/\.\d+(\.[^\.]+$)/.$n$1/;
                }
                else{
                    $file_path =~ s/(\.[^\.]+$)/.1$1/;
                }
            }
            spurt $bin,$file_path;
            $msg->media_path($file_path);
            $msg->media_name(basename($file_path));
            $msg->content("[media](". $msg->media_path . ")");
        };
        $client->warn("保存图片失败：$@") if $@;
    };

    $client->on(receive_media=>$callback,send_media=>$callback);
}
1;

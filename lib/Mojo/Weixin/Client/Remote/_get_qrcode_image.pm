use Encode ();
use Encode::Locale;
sub Mojo::Weixin::_get_qrcode_image{
    my $self = shift;
    my $qrcode_uuid = shift;
    my $api = 'https://login.weixin.qq.com/qrcode/';
    #my @query_string = (
    #    t => "webwx",
    #);
    my $url = $api . $qrcode_uuid;
    my $data = $self->http_get($url);
    if( not defined $data){
        $self->error("登录二维码下载失败");
        return 0;
    }
    $self->clean_qrcode();
    $self->die("未设置二维码保存路径") if not defined $self->qrcode_path;
    eval{
        open(my $fh,">",$self->qrcode_path) or die "$!\n";
        binmode $fh;
        print $fh $data;
        close $fh;
    };
    if($@){
        $self->error("二维码写入文件[ " . $self->qrcode_path . " ]失败: $@");
        return 0;
    }

    my $filename_for_log = Encode::encode("utf8",Encode::decode(locale_fs,$self->qrcode_path));
    #$self->info("二维码已下载到本地[ $filename_for_log ]\n二维码原始下载地址[ $url ]");
    $self->info("二维码已下载到本地[ $filename_for_log ]");
    $self->emit(input_qrcode=>$self->qrcode_path,$data);
    return 1;
}
1;

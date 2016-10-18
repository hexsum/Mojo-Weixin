package Mojo::Weixin::Plugin::ShowQRCodeInTerm;
our $PRIORITY = 0;
our $CALL_ON_LOAD = 1;
BEGIN{
    our $has_term_qrcode = 0;
    eval{require Term::QRCode;};
    $has_term_qrcode = 1 if not $@;
}
sub call{
    my $client = shift;
    my $data   = shift;

    $client->die("插件[". __PACKAGE__ ."]依赖模块 Term::QRCode，请先确认该模块已经正确安装。
        \e[33;1mlinux安装方法:
        \t1、wget http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz
        \t2、tar zxf qrencode-3.4.4.tar.gz
        \t3、cd qrencode-3.4.4;
        \t4、./configure;
        \t5、make && make install
        \t6、export PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig\"
        \t7、cpanm Term::QRCode \n\e[0m") if not $has_term_qrcode;

    $client->on(input_qrcode=>sub{
        my($client,$filename,$data,$qrcode_url) = @_;
        $client->info('请扫描屏幕二维码登陆！');
        print Term::QRCode->new->plot($qrcode_url) ;
        $count++;
    });
}
1;

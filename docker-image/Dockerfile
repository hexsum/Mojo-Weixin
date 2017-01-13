FROM perl:5.22
MAINTAINER sjdy521 <sjdy521@163.com>
WORKDIR /root
RUN apt-get update \
    && apt-get install -y unzip \
    && wget https://github.com/sjdy521/Mojo-Weixin/archive/master.zip -OMojo-Weixin.zip \
    && unzip -qo Mojo-Weixin.zip \
    && cd Mojo-Weixin-master \
    && cpanm . \
    && rm -rf Mojo-Weixin-master Mojo-Weixin.zip 
CMD perl -MMojo::Weixin -e 'Mojo::Weixin->new(log_encoding="utf8")->load(["ShowMsg","UploadQRcode"])->load("Openwx",data=>{listen=>[{port=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_PORT}//3000}],post_api=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_POST_API}})'

FROM centos:7.0.1406
MAINTAINER sjdy521 <sjdy521@163.com>
WORKDIR /root
USER root
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN yum -y --nogpgcheck install \
    make \
    unzip \ 
    wget \ 
    tar \
    perl \ 
    perl-App-cpanminus \
    perl-Compress-Raw-Zlib \
    perl-IO-Compress-Gzip \
    perl-Digest-MD5 \
    perl-Digest-SHA \
    perl-Time-Piece \
    perl-Time-Seconds \
    perl-Time-HiRes \
    perl-IO-Socket-SSL \
    perl-Encode-Locale \
    perl-Term-ANSIColor && \
    yum clean all
RUN cpanm -vn Test::More IO::Socket::SSL Mojolicious
RUN wget -q https://github.com/sjdy521/Mojo-Weixin/archive/master.zip -OMojo-Weixin.zip \
    && unzip -qo Mojo-Weixin.zip \
    && cd Mojo-Weixin-master \
    && cpanm -v . \
    && cd .. \
    && rm -rf Mojo-Weixin-master Mojo-Weixin.zip
CMD perl -MMojo::Weixin -e 'Mojo::Weixin->new(log_encoding=>"utf8")->load(["ShowMsg","UploadQRcode"])->load("Openwx",data=>{listen=>[{port=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_PORT}//3000}],post_api=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_POST_API}})->run'

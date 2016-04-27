FROM perl:5.22
MAINTAINER sjdy521 <sjdy521@163.com>
RUN cpanm Mojo::Weixin \
    && cpanm Mojo::SMTP::Client
WORKDIR /root
COPY Mojo-Weixin.pl Mojo-Weixin.pl
CMD ["perl","Mojo-Weixin.pl"]

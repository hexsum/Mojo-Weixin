use 5.010001;
use ExtUtils::MakeMaker "6.46";
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojo::Weixin',
    VERSION_FROM      => 'lib/Mojo/Weixin.pm', # finds $VERSION
    DISTNAME            => 'Mojo-Weixin',
    LICENSE             => "perl",
    PREREQ_PM         => {
        "Compress::Raw::Zlib"   => 0,
        "IO::Compress::Gzip"    => 0,
        "Time::HiRes"           => 0,
        "Time::Piece"           => 0,
        "Time::Seconds"         => 0,
        "Digest::SHA"           => 0,
        "Digest::MD5"           => 0,
        "Encode::Locale"        => 0,
        "IO::Socket::SSL"       => '2.009',
        "Mojolicious"           => '8.02',
    }, # e.g., Module::Name => 1.1
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Mojo-Weixin-* MANIFEST' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {     
            repository=>{
                type    => 'git',
                url     => 'git://github.com/sjdy521/Mojo-Weixin.git',
                web     =>  'https://github.com/sjdy521/Mojo-Weixin',
            },
        },
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       #ABSTRACT_FROM  => 'lib/Webqq/Client.pm', # retrieve abstract from module
       ABSTRACT       => 'A Weixin Client Framework base on Mojolicious',
       AUTHOR         => 'sjdy521 <sjdy521@163.com>') : ()),
);

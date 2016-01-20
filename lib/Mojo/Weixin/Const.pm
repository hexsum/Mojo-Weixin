package Mojo::Weixin::Const;
use Exporter 'import';
our @EXPORT = qw(%KEY_MAP_USER %KEY_MAP_FRIEND %KEY_MAP_GROUP %KEY_MAP_MESSAGE %KEY_MAP_GROUP_MEMBER);
our %KEY_MAP_MESSAGE = qw(
    time        CreateTime
    content     Content
    id          MsgId
);
our %KEY_MAP_USER = qw(
    id          UserName
    name        NickName
    alias       Alias
    province    Province
    city        City
    signature   Signature
    sex         Sex
    display     DisplayName
    markname    RemarkName
);
our %KEY_MAP_FRIEND = qw(
    id          UserName
    name        NickName
    alias       Alias
    province    Province
    city        City
    signature   Signature
    sex         Sex
    display     DisplayName
    markname    RemarkName

);
our %KEY_MAP_GROUP = qw(
    id      UserName
    name    NickName
);
our %KEY_MAP_GROUP_MEMBER = qw(
    id          UserName
    name        NickName
    alias       Alias
    province    Province
    city        City
    signature   Signature
    sex         Sex
    display     DisplayName
    markname    RemarkName
);
1;

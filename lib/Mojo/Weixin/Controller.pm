package Mojo::Weixin::Controller;
our $VERSION = '1.0.0';
use strict;
use warnings;
use Carp;
use Config;
use File::Spec;
use Mojo::Weixin::Base 'Mojo::EventEmitter';
use Mojo::Weixin;
use Mojo::Weixin::Server;
use Mojo::Weixin::Log;
use Mojo::UserAgent;
use Mojo::IOLoop;
use IO::Socket::IP;
use Time::HiRes ();
use Storable qw();
use POSIX qw();
use if $^O eq "MSWin32",'Win32::Process';
use if $^O eq "MSWin32",'Win32';
#use base qw(Mojo::Weixin::Util Mojo::Weixin::Request);
use base qw(Mojo::Weixin::Util);

has backend => sub{+{}};
has ioloop  => sub {Mojo::IOLoop->singleton};
has backend_start_port => 3000;
has post_api => undef;
has server =>  sub { Mojo::Weixin::Server->new };
has listen => sub { [{host=>"0.0.0.0",port=>2000},] };
has ua  => sub {Mojo::UserAgent->new(connect_timeout=>3,inactivity_timeout=>3,request_timeout=>3)};

has tmpdir              => sub {File::Spec->tmpdir();};
has pid_path            => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_controller_process','.pid'))};
has backend_path        => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_controller_backend','.dat'))};
has template_path        => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_controller_template','.pl'))};
has check_interval      => 5;

has log_level           => 'info';     #debug|info|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...
has log_head            => "[wxc][$$]";

has version             => sub{$Mojo::Weixin::Controller::VERSION};

has log     => sub{
    my $self = $_[0];
    Mojo::Weixin::Log->new(
        encoding    =>  $_[0]->log_encoding,
        path        =>  $_[0]->log_path,
        level       =>  $_[0]->log_level,
        format      =>  sub{
            my ($time, $level, @lines) = @_;
            my $title = "";
            my $head  = $self->log_head || "";
            if(ref $lines[0] eq "HASH"){
                my $opt = shift @lines; 
                $time = $opt->{"time"} if defined $opt->{"time"};
                $title = $opt->{"title"} . " " if defined $opt->{"title"};
                $level  = $opt->{"level"} if defined $opt->{"level"};
                $head  = $opt->{"head"} if defined $opt->{"head"};
            }
            @lines = split /\n/,join "",@lines;
            my $return = "";
            $time = $time?POSIX::strftime('[%y/%m/%d %H:%M:%S]',localtime($time)):"";
            $level = $level?"[$level]":"";
            for(@lines){$return .= $head . $time . " " . $level . " " . $title . $_ . "\n";}
            return $return;
        }
    )
};
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->info("当前正在使用 Mojo-Weixin-Controller v" . $self->version);
    $self->ioloop->reactor->on(error=>sub{
        my ($reactor, $err) = @_;
        $self->error("reactor error: " . Carp::longmess($err));
    });
    $SIG{__WARN__} = sub{$self->warn(Carp::longmess @_);};
    $self->on(error=>sub{
        my ($self, $err) = @_;
        $self->error(Carp::longmess($err));
    });
    if( $^O!~/^MSWin32/i and $Config{d_pseudofork}){
        $self->fatal("非常抱歉, Mojo-Weixin-Controller不支持您当前使用的系统");
        $self->stop();
    } 
    $self->check_pid();
    $self->load_backend(); 
    $self->check_client();
    $SIG{CHLD} =  'IGNORE';
    $SIG{INT} = $SIG{KILL} = $SIG{TERM} = $SIG{HUP} = sub{
        $self->info("正在停止Controller...");
        $self->save_backend();
        $self->clean_pid();
        $self->stop();
    };
    $0 = 'wxcontroller';
    $Mojo::Weixin::Controller::_CONTROLLER = $self;
    $self;
}
sub stop{
    my $self = shift;
    $self->info("Controller停止运行");
    CORE::exit();
}

sub save_backend{
    my $self = shift;
    my $backend_path = $self->backend_path;
    eval{Storable::nstore($self->backend,$backend_path);};
    $self->warn("Controller保存backend失败: $@") if $@;

}
sub load_backend {
    my $self = shift;
    my $backend_path = $self->backend_path;
    return if not -f $backend_path;
    eval{require Storable;$self->backend(Storable::retrieve($backend_path))};
    if($@){
        $self->warn("Controller加载backend失败: $@");
        return;
    }
    else{
        $self->info("Controller加载backend[ $backend_path ]");
    }
}
sub check_pid {
    my $self = shift;
    return if not $self->pid_path;
    eval{
        if(not -f $self->pid_path){
            $self->spurt($$,$self->pid_path);
        }
        else{
            my $pid = $self->slurp($self->pid_path);
            if( $pid=~/^\d+$/ and kill(0, $pid) ){
                $self->warn("检测到有其他运行中的Controller(pid:$pid), 请先将其关闭");
                $self->stop();
            }
            else{
                $self->spurt($$,$self->pid_path);
            }
        }
    };
    $self->warn("进程检测遇到异常: $@") if $@;
    
}


sub clean_pid {
    my $self = shift;
    return if not defined $self->pid_path;
    return if not -f $self->pid_path;
    $self->info("清除残留的Controller pid文件");
    unlink $self->pid_path or $self->warn("删除pid文件[ " . $self->pid_path . " ]失败: $!");
}

sub kill_process {
    my $self = shift;
    if(!$_[0] or $_[0]!~/^\d+$/){
        $self->error("pid无效，无法终止进程");
        return;
    }
    #if($^O  eq "MSWin32"){
    #    my $exitcode = 0;
    #    Win32::Process::KillProcess($_[0],$exitcode);
    #    return $exitcode;
    #}
    #else{ 
        kill POSIX::SIGINT,$_[0] ;
    #}
}
sub check_process {
    my $self = shift;
    if(!$_[0] or $_[0]!~/^\d+$/){
        $self->error("pid无效，无法终止进程");
        return;
    }
    #if($^O  eq "MSWin32"){
    #    my $p;
    #    return Win32::Process::Open($p,$_[0],0);
    #}
    else{ kill 0,$_[0] ;}
}
sub start_client {
    my $self = shift;
    my $param = shift;
    if(!$param->{client}){
        return {code => 1, status=>'client not found',};
    }
    elsif(exists $self->backend->{$param->{client}}){
        return {code=>0, status=>'client already exists',%{ $self->backend->{$param->{client}} }}
            if $self->check_process($self->backend->{$param->{client}}{pid});
    }
    my $backend_port = empty_port({host=>'127.0.0.1',port=>$self->backend_start_port,proto=>'tcp'});
    return {code => 2, status=>'no available port',client=>$param->{client}} if not defined $backend_port;
    my $post_api = $param->{post_api} || $self->post_api;
    if(defined $post_api){
        my $url = Mojo::URL->new($post_api);
        $url->query->merge(client=>$param->{client});
        $post_api =  $url->to_string;
    }
    $param->{account} = $param->{client};
    $self->reform_hash($param);

    for my $env(keys %ENV){
        delete $ENV{$env} if $env=~/^MOJO_WEIXIN_([A-Z_]+)$/;
    }
    for my $p (keys %$param){
        my $env_key = "MOJO_WEIXIN_" . uc($p);
        $ENV{$env_key} = $param->{$p};
    }
    $ENV{MOJO_WEIXIN_PLUGIN_OPENWX_PORT} = $backend_port;
    $ENV{MOJO_WEIXIN_PLUGIN_OPENWX_POST_API} = $post_api;
    local $ENV{PERL5LIB} = join( ($^O eq "MSWin32"?";":":"),@INC);
    if(!-f $self->template_path or -z $self->template_path){
        my $template =<<'MOJO_WEIXIN_CLIENT_TEMPLATE';
#!/usr/bin/env perl
use Mojo::Weixin;
my $client = Mojo::Weixin->new(log_head=>"[$ENV{MOJO_WEIXIN_ACCOUNT}][$$]");
$0 = "wxclient(" . $client->account . ")" if $^O ne "MSWin32";
$SIG{INT} = 'IGNORE' if ($^O ne 'MSWin32' and !-t);
$client->load(["ShowMsg","UploadQRcode","ShowQRcode"]);
$client->load("Openwx",data=>{listen=>[{host=>"127.0.0.1",port=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_PORT} }], post_api=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_POST_API} || undef,post_event=>$ENV{MOJO_WEIXIN_PLUGIN_OPENWX_POST_EVENT} // 1,post_media_data=> $ENV{MOJO_WEIXIN_PLUGIN_OPENWX_POST_MEDIA_DATA} // 1},call_on_load=>1);
$client->run();
MOJO_WEIXIN_CLIENT_TEMPLATE
        $self->spurt($template,$self->template_path);
    }
    $self->info("使用模版[" . $self->template_path .  "]创建客户端");
    if( $^O eq 'MSWin32'){#Windows
        my $process;
        no strict;
        my $p = $self->decode("gbk",$Config{perlpath});
        if($p=~/\p{Han}|\s+/){
            $self->warn("perl路径包含空格或中文可能导致客户端创建失败: [" . $self->encode("utf8",$p) . "]");
        }
        if(Win32::Process::Create($process,$Config{perlpath},'perl ' . $self->template_path,0,CREATE_NEW_PROCESS_GROUP,".") ){
            $self->backend->{$param->{client}} = $param;
            $self->backend->{$param->{client}}{pid} = $process->GetProcessID();
            $self->backend->{$param->{client}}{port} = $backend_port;
            delete $self->backend->{$param->{client}}{log_head};
            return {code=>0,status=>'success',%{ $self->backend->{$param->{client}} } };    
        }
        else{
            $self->error(
                "创建客户端失败: " . 
                $self->encode("utf8",
                    $self->decode("gbk",Win32::FormatMessage( Win32::GetLastError() ) || 'create client fail' ) 
                ) 
            );
            #$self->error(Win32::FormatMessage( Win32::GetLastError() ) );
            return {code=>3,status=>'failure',};
        }
    }
    else{#Unix 
        my $pid = fork();
        if($pid == 0) {#new process
            $self->server->stop;
            $self->ioloop->stop;
            delete $self->server->{servers};
            my $template_path = $self->template_path;
            undef $self;
            exec $Config{perlpath} || 'perl',$template_path;
        }
        else{
            sleep 2;
            $self->backend->{$param->{client}} = $param;
            $self->backend->{$param->{client}}{pid} = $pid;
            $self->backend->{$param->{client}}{port} = $backend_port;
            delete $self->backend->{$param->{client}}{log_head};
            return {code=>0,status=>'success',%{ $self->backend->{$param->{client}} } };
        }
    }
}

sub stop_client {
    my $self = shift;
    my $param = shift;
    if(!$param->{client}){
        return {code => 1, status=>'client not found',};
    }
    elsif(!exists $self->backend->{$param->{client}}){
        return {code => 1, status=>'client not exists',};
    }
    my $ret = $self->kill_process( $self->backend->{$param->{client}}{pid} );
    if ($ret){
        my $client = $self->backend->{$param->{client}};
        delete $self->backend->{$param->{client}};
        return {code=>0,status=>'success',%$client };
    }
    return {code=>1,status=>'failure'};
}

sub check_client {
    my $self = shift;
    for my $client ( keys %{ $self->backend }  ){
        my $pid = $self->backend->{$client}->{pid};
        my $ret = $self->check_process($pid);
        if(not $ret){
            $self->warn("检测到客户端 $client\[$pid\] 不存在，删除客户端信息");
            delete $self->backend->{$client};
        }
    }
}
sub run {
    my $self = shift;
    my $server =  $self->server;
    $server->app($server->build_app("Mojo::Weixin::Controller::App"));
    $server->app->defaults(wxc=>$self);
    $server->app->secrets("hello world");
    $server->app->log($self->log);
    $server->listen([ map { 'http://' . (defined $_->{host}?$_->{host}:"0.0.0.0") .":" . (defined $_->{port}?$_->{port}:2000)} @{ $self->listen } ]) ;
    $server->start;
    $self->ioloop->recurring($self->check_interval || 5,sub{
        $self->check_client();
        $self->save_backend();
    });
    $self->ioloop->start if not $self->ioloop->is_running;
}

package Mojo::Weixin::Controller::App;
use Mojolicious::Lite;
use Mojo::Transaction::HTTP;
get '/openwx/start_client' => sub{
    my $c = shift;
    my $hash   = $c->req->params->to_hash;
    my $result =  $c->stash('wxc')->start_client($hash);
    $c->render(json=>$result);
};
get '/openwx/stop_client' => sub{
    my $c = shift;
    my $hash   = $c->req->params->to_hash;
    my $result = $c->stash('wxc')->stop_client($hash);
    $c->render(json=>$result);
};
get '/openwx/check_client' => sub{
    my $c = shift;
    $c->render(json=>[ values %{ $c->stash('wxc')->backend } ]);    
};
any '/*whatever'  => sub{
    my $c = shift;
    my $client = $c->param('client');
    if(not $client){
        $c->render(json=>{code => 1, status=>'client not found',});
        return;
    }
    $c->render_later;
    my $tx = Mojo::Transaction::HTTP->new(req=>$c->req->clone);
    $tx->req->url->host("127.0.0.1");
    $tx->req->url->port($c->stash('wxc')->backend->{$client}->{port});
    $tx->req->url->scheme('http');
    $tx->req->headers->header('Host',$tx->req->url->host_port);
    return if $c->stash('mojo.finished');
    $c->ua->start($tx,sub{
        my ($ua,$tx) = @_;
        $c->tx->res($tx->res);
        $c->rendered;
    });
};
#any '/*whatever'  => sub{whatever=>'',$_[0]->render(text=>"api not found",status=>403)};
package Mojo::Weixin::Controller;

sub can_bind {
    my ($host, $port, $proto) = @_;
    # The following must be split across two statements, due to
    # https://rt.perl.org/Public/Bug/Display.html?id=124248
    my $s = _listen_socket($host, $port, $proto);
    return defined $s;
}
 
sub _listen_socket {
    my ($host, $port, $proto) = @_;
    $port  ||= 0;
    $proto ||= 'tcp';
    IO::Socket::IP->new(
        (($proto eq 'udp') ? () : (Listen => 5)),
        LocalAddr => $host,
        LocalPort => $port,
        Proto     => $proto,
        V6Only    => 1,
        (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
    );
}
 
sub listen_socket {
    my ($host, $proto) = @{$_[0]}{qw(host proto)};
    $host = '127.0.0.1' unless defined $host;
    return _listen_socket($host, undef, $proto);
}
 
# get a empty port on 49152 .. 65535
# http://www.iana.org/assignments/port-numbers
sub empty_port {
    my ($host, $port, $proto) = @_ && ref $_[0] eq 'HASH' ? ($_[0]->{host}, $_[0]->{port}, $_[0]->{proto}) : (undef, @_);
    $host = '127.0.0.1'
        unless defined $host;
    if (defined $port) {
        $port = 49152 unless $port =~ /^[0-9]+$/ && $port < 49152;
    } else {
        $port = 50000 + (int(rand()*1500) + abs($$)) % 1500;
    }
    $proto = $proto ? lc($proto) : 'tcp';
 
    $port--;
    while ( $port++ < 65000 ) {
        # Remote checks don't work on UDP, and Local checks would be redundant here...
        next if ($proto eq 'tcp' && check_port({ host => $host, port => $port }));
        return $port if can_bind($host, $port, $proto);
    }
    return;
}
 
sub check_port {
    my ($host, $port, $proto) = @_ && ref $_[0] eq 'HASH' ? ($_[0]->{host}, $_[0]->{port}, $_[0]->{proto}) : (undef, @_);
    $host = '127.0.0.1'
        unless defined $host;
    $proto = $proto ? lc($proto) : 'tcp';
 
    # for TCP, we do a remote port check
    # for UDP, we do a local port check, like empty_port does
    my $sock = ($proto eq 'tcp') ?
        IO::Socket::IP->new(
            Proto    => 'tcp',
            PeerAddr => $host,
            PeerPort => $port,
            V6Only   => 1,
        ) :
        IO::Socket::IP->new(
            Proto     => $proto,
            LocalAddr => $host,
            LocalPort => $port,
            V6Only   => 1,
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        )
    ;
 
    if ($sock) {
        close $sock;
        return 1; # The port is used.
    }
    else {
        return 0; # The port is not used.
    }
 
}
1;

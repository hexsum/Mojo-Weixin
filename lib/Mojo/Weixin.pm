package Mojo::Weixin;
our $VERSION = '1.3.7';
use Mojo::Weixin::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Mojo::Weixin::Log;
use File::Spec ();
use POSIX ();
use Carp ();
use base qw(Mojo::Weixin::Util Mojo::Weixin::Model Mojo::Weixin::Client Mojo::Weixin::Plugin Mojo::Weixin::Request);

has http_debug          => sub{$ENV{MOJO_WEIXIN_HTTP_DEBUG} || 0 } ;
has ua_debug            => sub{$_[0]->http_debug};
has ua_debug_req_body   => sub{$_[0]->ua_debug};
has ua_debug_res_body   => sub{$_[0]->ua_debug};
has log_level           => 'info';     #debug|info|msg|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...
has log_head            => undef;
has log_console         => 1;
has log_unicode         => 0;
has download_media      => 1;
has disable_color       => 0;           #是否禁用终端打印颜色
has send_interval       => 3;           #全局发送消息间隔

has is_init_group_member => 0;
has is_update_group_member => 1;
has is_update_all_friend => 1;

has account             => sub{ $ENV{MOJO_WEIXIN_ACCUNT} || 'default'};
has start_time          => time;
has tmpdir              => sub {$ENV{MOJO_WEIXIN_TMPDIR} || File::Spec->tmpdir();};
has media_dir           => sub {$_[0]->tmpdir};
has cookie_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_cookie_',$_[0]->account || 'default','.dat'))};
has qrcode_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_qrcode_',$_[0]->account || 'default','.jpg'))};
has pid_path            => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_pid_',$_[0]->account || 'default','.pid'))};
has state_path          => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_state_',$_[0]->account || 'default','.json'))};
has ioloop              => sub {Mojo::IOLoop->singleton};
has keep_cookie         => 1;
has fix_media_loop      => 1;
has synccheck_interval  => 1;
has synccheck_delay     => 1;
has _synccheck_interval => sub{ $_[0]->synccheck_interval};
has sync_interval       => 0;
has emoji_to_text       => 1;
has stop_with_mobile    => 0;
has http_max_message_size  => undef; #16777216;
has controller_pid      => sub{$ENV{MOJO_WEIXIN_CONTROLLER_PID}};

has user    => sub {+{}};
has friend  => sub {[]};
has group   => sub {[]};
has data    => sub {+{}};

has version => $Mojo::Weixin::VERSION;
has plugins => sub{+{}};
has log     => sub{
    Mojo::Weixin::Log->new(
        encoding    =>  $_[0]->log_encoding,
        unicode_support => $_[0]->log_unicode,
        path        =>  $_[0]->log_path,
        level       =>  $_[0]->log_level,
        head        =>  $_[0]->log_head,
        disable_color   => $_[0]->disable_color,
        console_output  => $_[0]->log_console,
    )
};

has is_ready                => 0;
has is_stop                 => 0;
has ua_retry_times          => 5;
has ua_connect_timeout      => 10;
has ua_request_timeout      => 35;
has ua_inactivity_timeout   => 35;
has is_first_login          => -1;
has login_state             => 'init';
has qrcode_upload_url       => undef;
has qrcode_uuid             => undef;
has qrcode_count            => 0;
has qrcode_count_max        => 10;
has media_size_max          => sub{20 * 1024 * 1024}; #运行上传的最大文件大小
has media_chunk_size        => sub{512 * 1024};#chunk upload 每个分片的大小
has ua                      => sub {
    my $self = $_[0];
    #local $ENV{MOJO_USERAGENT_DEBUG} = $_[0]->ua_debug;
    local $ENV{MOJO_MAX_MESSAGE_SIZE} = $_[0]->http_max_message_size if defined $_[0]->http_max_message_size;
    require Mojo::UserAgent;
    require Mojo::UserAgent::Proxy;
    require Storable if $_[0]->keep_cookie;
    my $transactor = Mojo::UserAgent::Transactor->new(
        name =>  'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062'
    );
    my $default_form_generator = $transactor->generators->{form};
    $transactor->add_generator(form => sub{
        #my ($self, $tx, $form, %options) = @_;
        $self->reform($_[2],unicode=>1,recursive=>1,filter=>sub{
            my($type,$deep,$key) = @_;
            return 1 if $type ne 'HASH';
            return 1 if $deep == 0;
            return 0 if $deep == 1 and $key =~ /^filename|file|content$/;
            return 1;
        });
        $default_form_generator->(@_);
    });
    $transactor->add_generator(json=>sub{
        $_[1]->req->body($self->to_json($_[2]))->headers->content_type('application/json');
        return $_[1];
    });
    Mojo::UserAgent->new(
        proxy              => sub{ my $proxy = Mojo::UserAgent::Proxy->new;$proxy->detect;$proxy}->(),
        max_redirects      => 7,
        connect_timeout    => $_[0]->ua_connect_timeout,
        request_timeout    => $_[0]->ua_request_timeout,
        inactivity_timeout => $_[0]->ua_inactivity_timeout,
        transactor         => $transactor,
    );
};

has message_queue => sub{$_[0]->gen_message_queue()};
has pass_ticket => '';
has skey => '';
has wxsid => '';
has wxuin => '';
has domain => 'wx.qq.com';
has lang   => 'zh_CN';

has _sync_running => 0;
has _synccheck_running => 0;
has _synccheck_error_count => 0;
has _synccheck_connection_id => undef;

has sync_key => sub{+{List=>[]}};
sub synccheck_key {
    my $self = shift;
    if(@_==0){
        return $self->{synccheck_key} // $self->sync_key;
    }
    else{
        $self->{synccheck_key} = $_[0];
        return $self;
    }
}

sub deviceid { return "e" . substr(rand() . ("0" x 15),2,15);}
sub state {
    my $self = shift;
    $self->{state} = 'init' if not defined $self->{state};
    if(@_ == 0){#get
        return $self->{state};
    } 
    elsif($_[0] and $_[0] ne $self->{state}){#set
        my($old,$new) = ($self->{state},$_[0]);
        $self->{state} = $new;
        $self->emit(state_change=>$old,$new);
    }
    $self;
}
sub on {
    my $self = shift;
    my @return;
    while(@_){
        my($event,$callback) = (shift,shift);
        push @return,$self->SUPER::on($event,$callback);
    }
    return wantarray?@return:$return[0];
}
sub emit {
    my $self = shift;
    $self->SUPER::emit(@_);
    $self->SUPER::emit(all_event=>@_);
}

sub wait_once {
    my $self = shift;
    my($timeout,$timeout_callback,$event,$event_callback)=@_;
    my ($timer_id, $subscribe_id);
    $timer_id = $self->timer($timeout,sub{
        $self->unsubscribe($event,$subscribe_id);
        $timeout_callback->(@_) if ref $timeout_callback eq "CODE";
    });
    $subscribe_id = $self->once($event=>sub{
        $self->ioloop->remove($timer_id);
        $event_callback->(@_) if ref $event_callback eq "CODE";
    });
    $self;
}

sub wait {
    my $self = shift;
    my($timeout,$timeout_callback,$event,$event_callback)=@_;
    my ($timer_id, $subscribe_id);
    $timer_id = $self->timer($timeout,sub{
        $self->unsubscribe($event,$subscribe_id);
        $timeout_callback->(@_) if ref $timeout_callback eq "CODE";;
    });
    $subscribe_id = $self->on($event=>sub{
        my $ret = ref $event_callback eq "CODE"?$event_callback->(@_):0;
        if($ret){ $self->ioloop->remove($timer_id);$self->unsubscribe($event,$subscribe_id); }
    });
    $self;
}
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    #$ENV{MOJO_USERAGENT_DEBUG} = $self->{ua_debug};
    
    for my $env(keys %ENV){
        if($env=~/^MOJO_WEIXIN_([A-Z_]+)$/){
            my $attr = lc $1;
            next if $attr =~ /^plugin_/;
            $self->$attr($ENV{$env}) if $self->can($attr);
        }
    }

    $self->info("当前正在使用 Mojo-Weixin v" . $self->version);
    $self->ioloop->reactor->on(error=>sub{
        return;
        my ($reactor, $err) = @_;
        $self->error("reactor error: " . Carp::longmess($err));
    });
    $SIG{__WARN__} = sub{$self->warn(Carp::longmess @_);};
    $self->on(error=>sub{
        my ($self, $err) = @_;
        $self->error(Carp::longmess($err));
    });
    $self->check_pid();
    $self->check_controller(1);
    $self->load_cookie();
    $self->save_state();
    $SIG{CHLD} = 'IGNORE';
    $SIG{INT}  = $SIG{TERM} = $SIG{HUP} = sub{
        if($^O ne 'MSWin32' and $_[0] eq 'INT' and !-t){
            $self->warn("后台程序捕获到信号[$_[0]]，已将其忽略，程序继续运行");
            return;
        }
        $self->info("捕获到停止信号[$_[0]]，准备停止...");
        $self->stop();
    };
    $self->on(stop=>sub{
        my $self = shift;
        $self->clean_qrcode();
        $self->clean_pid();
    });
    $self->on(state_change=>sub{
        my $self = shift;
        $self->save_state(@_);
    });
    $self->on(qrcode_expire=>sub{
        my($self) = @_;
        my $count = $self->qrcode_count;
        $self->qrcode_count(++$count);
        if($self->qrcode_count >= $self->qrcode_count_max){
            $self->stop();
        }
    });
    if($self->fix_media_loop){
        $self->on(receive_message=>sub{
            my($self,$msg) = @_;
            $self->synccheck_interval($msg->format eq "media"?3:1);
        });
        $self->on(send_message=>sub{
            my($self,$msg,$status) = @_;
            $self->synccheck_interval($msg->format eq "media"?3:1);
            $msg->reply(" ") if $self->fix_media_loop == 2;
        });
    }
    $self->on(update_friend=>sub{
        my $self = shift;
        my $filehelper = Mojo::Weixin::Friend->new(name=>"文件传输助手",id=>"filehelper");
        $self->add_friend($filehelper) if not $self->search_friend(id=>"filehelper");
    });
    $Mojo::Weixin::Message::SEND_INTERVAL = $self->send_interval;
    $Mojo::Weixin::_CLIENT = $self;
    $self;
}

1;

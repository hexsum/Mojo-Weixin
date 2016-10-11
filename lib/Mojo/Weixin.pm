package Mojo::Weixin;
our $VERSION = '1.2.1';
use Mojo::Weixin::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Mojo::Weixin::Log;
use File::Spec ();
use POSIX ();
use Carp ();
use base qw(Mojo::Weixin::Util Mojo::Weixin::Model Mojo::Weixin::Client Mojo::Weixin::Plugin Mojo::Weixin::Request);

has http_debug          => 0;
has ua_debug            => sub{$_[0]->http_debug};
has ua_debug_req_body   => sub{$_[0]->ua_debug};
has ua_debug_res_body   => sub{$_[0]->ua_debug};
has log_level           => 'info';     #debug|info|warn|error|fatal
has log_path            => undef;
has log_encoding        => undef;      #utf8|gbk|...

has account             => 'default';
has start_time          => time;
has tmpdir              => sub {File::Spec->tmpdir();};
has media_dir           => sub {$_[0]->tmpdir};
has cookie_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_cookie_',$_[0]->account || 'default','.dat'))};
has qrcode_path         => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_qrcode_',$_[0]->account || 'default','.jpg'))};
has pid_path            => sub {File::Spec->catfile($_[0]->tmpdir,join('','mojo_weixin_pid_',$_[0]->account || 'default','.pid'))};
has ioloop              => sub {Mojo::IOLoop->singleton};
has keep_cookie         => 1;
has fix_media_loop      => 1;
has synccheck_interval  => 1;
has emoji_to_text       => 1;
has stop_with_mobile    => 0;

has user    => sub {+{}};
has friend  => sub {[]};
has group   => sub {[]};
has data    => sub {+{}};

has version => $Mojo::Weixin::VERSION;
has plugins => sub{+{}};
has log     => sub{
    Mojo::Weixin::Log->new(
        encoding    =>  $_[0]->log_encoding,
        path        =>  $_[0]->log_path,
        level       =>  $_[0]->log_level,
        format      =>  sub{
            my ($time, $level, @lines) = @_;
            my $title = "";
            if(ref $lines[0] eq "HASH"){
                my $opt = shift @lines; 
                $time = $opt->{"time"} if defined $opt->{"time"};
                $title = $opt->{title} . " " if defined $opt->{"title"};
                $level  = $opt->{level} if defined $opt->{"level"};
            }
            @lines = split /\n/,join "",@lines;
            my $return = "";
            $time = $time?POSIX::strftime('[%y/%m/%d %H:%M:%S]',localtime($time)):"";
            $level = $level?"[$level]":"";
            for(@lines){$return .= $time . " " . $level . " " . $title . $_ . "\n";}
            return $return;
        }
    )
};

has is_ready                => 0;
has is_stop                 => 0;
has ua_retry_times          => 5;
has is_first_login          => -1;
has login_state             => 'init';
has qrcode_count            => 0;
has qrcode_count_max        => 10;
has ua                      => sub {
    #local $ENV{MOJO_USERAGENT_DEBUG} = $_[0]->ua_debug;
    require Mojo::UserAgent;
    require Mojo::UserAgent::Proxy;
    require Storable if $_[0]->keep_cookie;
    Mojo::UserAgent->new(
        proxy              => sub{ my $proxy = Mojo::UserAgent::Proxy->new;$proxy->detect;$proxy}->(),
        max_redirects      => 7,
        request_timeout    => 120,
        inactivity_timeout => 120,
        transactor => Mojo::UserAgent::Transactor->new( 
            name =>  'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062'
        ),
    );
};

has message_queue => sub{$_[0]->gen_message_queue()};

has sync_key => sub{+{}};
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

sub deviceid { return "e" . substr(rand . ("0" x 15),2,15);}
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
    $self->info("当前正在使用 Mojo-Weixin v" . $self->version);
    $self->ioloop->reactor->on(error=>sub{
        my ($reactor, $err) = @_;
        $self->error("reactor error: " . Carp::longmess($err));
    });
    $SIG{__WARN__} = sub{$self->warn(Carp::longmess @_);};
    $self->on(error=>sub{
        my ($self, $err) = @_;
        $self->error(Carp::longmess($err));
    });
    $self->check_pid();
    $SIG{INT} = $SIG{KILL} = $SIG{TERM} = sub{
        $self->clean_qrcode();
        $self->clean_pid();
        $self->stop();
    };
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
    $Mojo::Weixin::_CLIENT = $self;
    $self;
}

1;

package Mojo::Weixin::Util;
use Carp qw();
use Encode ();
use IO::Handle;
use Mojo::Util ();
use Mojo::JSON qw();
use Mojo::Weixin::Const qw(%FACE_MAP_QQ %FACE_MAP_EMOJI);
my %emoji_to_text_map = reverse %FACE_MAP_EMOJI;
sub emoji_convert {
    my $self = shift; 
    my $content_ref =  shift;
    return $self if not $$content_ref;
    my $is_emoji_to_text = shift; $is_emoji_to_text = 1 if not defined $is_emoji_to_text;
    if($is_emoji_to_text){
        $$content_ref=~s/<span class="emoji emoji([a-zA-Z0-9]+)"><\/span>/exists $emoji_to_text_map{$1}?"[$emoji_to_text_map{$1}]":"[未知表情]"/ge;
    }
    else{
        use bigint;
        $$content_ref=~s/<span class="emoji emoji([a-zA-Z0-9]+)"><\/span>/$self->encode_utf8(chr(hex($1)))/ge;
    }
    return $self;
}
sub now {
    my $self = shift;
    return int Time::HiRes::time() * 1000;
}
sub encode{
    my $self = shift;
    return Mojo::Util::encode(@_);
}
sub decode{
    my $self = shift;
    return Mojo::Util::decode(@_);
}
sub encode_utf8{
    my $self = shift;
    return Mojo::Util::encode("utf8",@_);
}
sub url_escape{
    my $self = shift;
    return Mojo::Util::url_escape(@_);
}
sub b64_encode {
    my $self = shift;
    return Mojo::Util::b64_encode(@_);
}
sub slurp {
    my $self = shift;
    my $path = shift;

    open my $file, '<', $path or Carp::croak qq{Can't open file "$path": $!};
    my $ret = my $content = '';
    while ($ret = $file->sysread(my $buffer, 131072, 0)) { $content .= $buffer }
    Carp::croak qq{Can't read from file "$path": $!} unless defined $ret;

    return $content;
}
sub spurt {
    my $self = shift;
    my ($content, $path) = @_;
    open my $file, '>', $path or Carp::croak qq{Can't open file "$path": $!};
    defined $file->syswrite($content)
        or Carp::croak qq{Can't write to file "$path": $!};
    return $content;
}
sub from_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::from_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "::from_json return undef value");
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "::from_json return undef value") if not defined $r;
        return $r;
    }
}
sub to_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::to_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "::to_json return undef value");
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "::to_json return undef value") if not defined $r;
        return $r;
    }
}
sub decode_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::decode_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "::decode_json return undef value");
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "::decode_json return undef value") if not defined $r;
        return $r;
    }
}
sub encode_json{
    my $self = shift;
    my $r = eval{
        Mojo::JSON::encode_json(@_);
    };
    if($@){
        $self->warn($@);
        $self->warn(__PACKAGE__ . "encode_json return undef value") if not defined $r;
        return undef;
    }
    else{
        $self->warn(__PACKAGE__ . "encode_json return undef value") if not defined $r;
        return $r;
    }
}

sub truncate {
    my $self = shift;
    my $out_and_err = shift || '';
    my %p = @_;
    my $max_bytes = $p{max_bytes} || 200;
    my $max_lines = $p{max_lines} || 10;
    my $is_truncated = 0;
    if(length($out_and_err)>$max_bytes){
        $out_and_err = substr($out_and_err,0,$max_bytes);
        $is_truncated = 1;
    }
    my @l =split /\n/,$out_and_err,$max_lines+1;
    if(@l>$max_lines){
        $out_and_err = join "\n",@l[0..$max_lines-1];
        $is_truncated = 1;
    }
    return $out_and_err. ($is_truncated?"\n(已截断)":"");
}
sub reform{
    my $self = shift;
    my $ref = shift;
    my %opt = @_;
    my $unicode = $opt{unicode} // 0;
    my $recursive = $opt{recursive} // 1;
    my $cb = $opt{filter};
    my $deep = $opt{deep} // 0;
    if(ref $ref eq 'HASH'){
        my @reform_hash_keys;
        for (keys %$ref){
            next if ref $cb eq "CODE" and !$cb->("HASH",$deep,$_,$ref->{$_});
            if($_ !~ /^[[:ascii:]]+$/){
                if($unicode and not Encode::is_utf8($_)){
                    push @reform_hash_keys,[ $_,Encode::decode_utf8($_) ];
                }
                elsif(!$unicode and Encode::is_utf8($_)){ 
                    push @reform_hash_keys,[ $_,Encode::encode_utf8($_) ];
                }
            }
        
            if(ref $ref->{$_} eq ""){
                if($unicode and not Encode::is_utf8($ref->{$_}) ){
                    Encode::_utf8_on($ref->{$_});
                }
                elsif( !$unicode and Encode::is_utf8($ref->{$_}) ){
                    Encode::_utf8_off($ref->{$_});
                }
            }
            elsif( $recursive and ref $ref->{$_} eq "ARRAY" or ref $ref->{$_} eq "HASH"){
                $self->reform($ref->{$_},@_,deep=>$deep+1);
            }
            #else{
            #    $self->die("不支持的hash结构\n");
            #}
        }

        for(@reform_hash_keys){ $ref->{$_->[1]} = delete $ref->{$_->[0]} }
    }
    elsif(ref $ref eq 'ARRAY'){
        for(@$ref){
            next if ref $cb eq "CODE" and !$cb->("ARRAY",$deep,$_);
            if(ref $_ eq ""){
                if($unicode and not Encode::is_utf8($_) ){
                    Encode::_utf8_on($_);
                }
                elsif( !$unicode and Encode::is_utf8($_) ){
                    Encode::_utf8_off($_);
                }
            }
            elsif($recursive and ref $_ eq "ARRAY" or ref $_ eq "HASH"){
                $self->reform($_,@_,deep=>$deep+1);
            }
            #else{
            #    $self->die("不支持的hash结构\n");
            #}
        }
    }
    else{
        $self->die("不支持的数据结构");
    }
    $self;
}
sub array_diff{
    my $self = shift;
    my $old = shift;
    my $new = shift;
    my $compare = shift;
    my $old_hash = {};
    my $new_hash = {};
    my $added = [];
    my $deleted = [];
    my $same = {};

    my %e = map {$compare->($_) => undef} @{$new};
    for(@{$old}){
        unless(exists $e{$compare->($_)}){
            push @{$deleted},$_;    
        }
        else{
            $same->{$compare->($_)}[0] = $_;
        }
    }

    %e = map {$compare->($_) => undef} @{$old};
    for(@{$new}){
        unless(exists $e{$compare->($_)}){
            push @{$added},$_;
        }
        else{
            $same->{$compare->($_)}[1] = $_;
        }
    }
    return $added,$deleted,[values %$same]; 
}

sub array_unique {
    my $self = shift;
    my $diff = pop;
    my $array = shift;
    my @result;
    my %info;
    my %tmp;
    for(@$array){
        my $id = $diff->($_);
        $tmp{$id}++;
    }
    for(@$array){
        my $id = $diff->($_);
        next if not exists $tmp{$id} ;
        next if $tmp{$id}>1;
        push @result,$_;
        $info{$id} = $_ if wantarray;
    }
    return wantarray?(\@result,\%info):\@result;
}
sub die{
    my $self = shift; 
    local $SIG{__DIE__} = sub{$self->log->fatal(@_);exit -1};
    Carp::confess(@_);
}
sub info{
    my $self = shift;
    $self->log->info(@_);
    $self;
}
sub warn{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'yellow' and $_[0]->{content_color} //= 'yellow')
    :   unshift @_,{level_color=>'yellow',content_color=>'yellow'};
    $self->log->warn(@_);
    $self;
}
sub msg{
    my $self = shift;
    $self->log->msg(@_);
    $self;
}
sub error{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'red' and $_[0]->{content_color} //= 'red')
    :   unshift @_,{level_color=>'red',content_color=>'red'};
    $self->log->error(@_);
    $self;
}
sub fatal{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'red' and $_[0]->{content_color} //= 'red')
    :   unshift @_,{level_color=>'red',content_color=>'red'};
    $self->log->fatal(@_);
    $self;
}
sub debug{
    my $self = shift;
    ref $_[0] eq 'HASH' ?
        ($_[0]->{level_color} //= 'blue' and $_[0]->{content_color} //= 'blue')
    :   unshift @_,{level_color=>'blue',content_color=>'blue'};
    $self->log->debug(@_);
    $self;
}
sub print {
    my $self = shift;
    #my $flag = 1;
    #if($flag){
        $self->log->info({time=>'',level=>'',},join (defined $,?$,:''),@_);
    #}
    #else{
    #    $self->log->info(join (defined $,?$,:''),@_);
    #}
    $self;
}

1;

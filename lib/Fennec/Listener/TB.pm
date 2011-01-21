package Fennec::Listener::TB;
use strict;
use warnings;

use base 'Fennec::Listener';

use Fennec::Util qw/accessors get_test_call/;
use POSIX ":sys_wait_h";

accessors qw/read write pid reporter_pid/;

sub new {
    my $class = shift;
    my ( $read, $write );
    pipe( $read, $write );

    my $self = bless({
        pid => $$,
        read => $read,
        write => $write,
    }, $class);

    $self->spawn_reporter;
    close( $read );
    $self->read( undef );

    my $old = select( $write );
    $| = 0;
    select( $old );

    $self->setup_tb;

    return $self;
}

sub ok {
    my $self = shift;
    my ( $status, $name, @diag ) = @_;

    require Test::More;

    Test::More::ok( $status, $name );
    return $status if $status;

    Test::More::diag( $_ ) for @diag;
    return $status;
}

sub setup_tb {
    my $self = shift;
    Test::Builder->new->use_numbers(0);
    my $out = $self->write;

    no warnings 'redefine';
    *Test::Builder::_ending = sub { 1 };

    my $original_print = Test::Builder->can('_print_to_fh');
    *Test::Builder::_print_to_fh = sub {
        my( $tb, $fh, @msgs ) = @_;

        my ( $handle, $output );
        open( $handle, '>', \$output );
        $original_print->( $tb, $handle, @msgs );
        close( $handle );

        my $ohandle = ($fh == $tb->output) ? 'STDOUT' : 'STDERR';

        my @call = get_test_call();
        print $out join( "\0", $$, $ohandle, $call[0], $call[1], $call[2], $_ ) . "\n"
            for split( /[\n\r]+/, $output );
    };
}

sub spawn_reporter {
    my $self = shift;
    my $pid = fork();

    if ( $pid ) {
        $self->reporter_pid( $pid );
        return $pid;
    }

    my $write = $self->write;
    close( $write );
    $self->write(undef);

    accessors qw/buffer count error_count/;

    $self->buffer({});
    $self->count(0);
    $self->error_count(0);
    $self->listen;
}

sub listen {
    my $self = shift;
    require Time::HiRes;
    my $alarm = \&Time::HiRes::alarm;
    local $SIG{ALRM} = sub { $self->flush; $alarm->( 0.10 )};
    my $read = $self->read;

    $alarm->(0.10);
    while( my $line = <$read> ) {
        $self->handle_line( $line );
    }

    $alarm->(0);
    $self->flush while keys %{ $self->buffer };

    print STDOUT "1.." . $self->count . "\n";
    exit( $self->error_count || 0 );
}

sub handle_line {
    my $self = shift;
    my ( $line ) = @_;
    my ( $pid, $handle, $class, $file, $ln, $msg ) = split( "\0", $line );
    my $id = "$class\0$file\0$ln";
    my $buffer = $self->buffer->{$pid};

    if ( !$buffer || $buffer->{id} ne $id ) {
        $self->render_buffer( $buffer ) if $buffer;
        $buffer = {
            id    => $id,
            lines => [],
        };
    }

    push @{ $buffer->{lines} } => [ $handle, $msg ];
    $self->buffer->{$pid} = $buffer;
}

sub flush {
    my $self = shift;
    for my $pid ( keys %{ $self->buffer }) {
        my $wait = waitpid( $pid, WNOHANG );
        next unless $wait == -1
                 || $wait == $pid;
        $self->render_buffer(
            delete $self->buffer->{ $pid }
        );
    }
}

sub render_buffer {
    my $self = shift;
    my ( $buffer ) = @_;
    require TAP::Parser;

    for my $line ( @{ $buffer->{ lines }}) {
        my $parser = TAP::Parser->new({ source => $line->[1] });
        while ( my $result = $parser->next ) {
            next if $result->is_plan;
            if( $result->is_test ) {
                $self->count( $self->count + 1 );
                $self->error_count( $self->error_count + 1 )
                    if !$result->is_ok;
            }
            if ( $line->[0] eq 'STDERR' && !$ENV{HARNESS_IS_VERBOSE} ) {
                print STDERR $result->raw . "\n";
            }
            else {
                print STDOUT $result->raw . "\n";
            }
        }
    }
}

sub terminate {
    my $self = shift;

    my $write = $self->write;
    close( $write );
    $self->write( undef );

    waitpid( $self->reporter_pid, 0 );
    my $exit = $? >> 8;
    exit( $exit );
}

sub DESTROY {
    my $self = shift;
    my $write = $self->write;
    close( $write ) if $write;
}

1;

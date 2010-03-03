package Fennec::Plugin::More;
use strict;
use warnings;

use Fennec::Plugin;

our @SUBS;
BEGIN {
    @SUBS = qw/ is isnt like unlike cmp_ok is_deeply can_ok isa_ok /;
}

use Test::More import => \@SUBS;

tester $_ => $_ for @SUBS;

util diag => sub { Fennec::Tester->diag( @_ ) };

util todo => sub(&$) {
    my ( $code, $todo ) = @_;
    local $Fennec::Plugin::TODO = $todo;
    $code->();
};

1;

=pod

=head1 NAME

Fennec::Plugin::More - Wrapper around L<Test::More> for Fennec

=head1 DESCRIPTION

Wraps all the testers from L<Test::More> for use in Fennec. Also provides
diag() and a new todo() function.

=head1 EARLY VERSION WARNING

This is VERY early version. Fennec does not run yet.

Please go to L<http://github.com/exodist/Fennec> to see the latest and
greatest.

=head1 TESTER FUNCTIONS

Please see L<Test::More> for more details on any of these.

=over 4

=item is()

=item isnt()

=item like()

=item unlike()

=item cmp_ok()

=item is_deeply()

=item can_ok()

=item isa_ok()

=back

=head1 UTILITY FUNCTIONS

=over 4

=item diag( @messages )

Display a message in the test output.

=item todo( $sub, $reason )

Run a group of tests under TODO.

    todo {
        ok( 0, "Will fail" );
        is( 1, 2, "1 != 2" );
    } "These fail";

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Fennec is free software; Standard perl licence.

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.

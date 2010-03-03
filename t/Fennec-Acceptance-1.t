#!/usr/bin/perl
use strict;
use warnings;

my $tester;
BEGIN {
    require Fennec::Tester;
    $tester = Fennec::Tester->new( _config => 1, no_load => 1, files => []);
}

use Fennec random => 1;

test_case 'a' => sub {1};
test_case 'b' => sub {1};
test_case 'c' => sub {1};
test_case 'd' => sub {1};

test_set set_a => sub {
    ok( 1, "Simple ok set a" );
};

test_set set_b => sub {
    ok( 1, "Simple ok set b" );
};

test_set set_c => sub {
    ok( 1, "Simple ok set c" );
};

test_set set_d => sub {
    ok( 1, "Simple ok set d" );
};

test_set set_e => sub {
    is_deeply( { a => 'a' }, { a => 'a' }, "is_deeply" );
};

$tester->run;


1;

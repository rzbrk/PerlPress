#!/usr/bin/perl -T

use Test::More;
use utf8;

use PerlPress::Tools;

########################################################################
diag( "Testing PerlPress::Tools::clearstr()" );

# Testing arguments
eval { PerlPress::Tools::clearstr() } or my $at=$@;
like( $at, qr/Specify title/, "die if no arg" );
is( PerlPress::Tools::clearstr({ str=>"a"x10, max_len=>5 }), "a"x5, "length" );

my $str="__abc_ABC_àéß {[]}\nµæ €§\$_";
is( PerlPress::Tools::clearstr({ str=>$str }), "abc_abc_aess_uae_euro", "testing special char");

########################################################################



done_testing();

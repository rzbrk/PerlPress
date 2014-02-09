#!/usr/bin/perl -T

use Test::More;
use utf8;

use PerlPress::Tools;

########################################################################
##
## clearstr
##
########################################################################
diag( "Testing \"clearstr\"" );
{
    # Testing arguments
    eval { PerlPress::Tools::clearstr() } or my $at=$@;
    like( $at, qr/Specify title/, "Test: die if no arg" );

    # Cutting to correct length
    is(
        PerlPress::Tools::clearstr({
            str=>"a"x10,
            max_len=>5,
        }),
        "a"x5,
        "Test: cutting to correct length"
    );

    # Handling of special characters
    my $str="__abc_ABC_àéß {[]}\nµæ €§\$_";
    is(
        PerlPress::Tools::clearstr({ str=>$str }),
        "abc_abc_aess_uae_euro",
        "Testing: Handling of special characters"
    );
}

########################################################################
done_testing();

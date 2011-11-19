#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Weightbot::API' ) || print "Bail out!
";
}

diag( "Testing Weightbot::API $Weightbot::API::VERSION, Perl $], $^X" );

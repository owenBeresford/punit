# No i am not trying to be clever with this name.
use strict;
use warnings;

# TRUE and FALSE
use constant::boolean;
use Test::More;
use Test::Assert ':assert';
# test::assert uses Exceptions
use Try::Tiny;

use_ok( 'punit::SkelGen');
my $t= punit::SkelGen->new('punit::IOAccess', 0, 0);
# this test is of limited utility, we need a subclass.
if( -f './punit/t/IOAccessTest.t') {
	die("Test failed, the unit test for 'punit::IOAaccess' already exists.  As you may want this, aborting.");
}

# rattle through these, then repeat for fixtures
# must do fixtures for the private functions etc.
assert_equals( $t->generateTest(), $t, "Should be able to make a fresh unit test");

assert_equals( $t->setTarget('punit::ClassGen'), $t, "Change to classGen" );
assert_equals( $t->generateTest(), $t, "Should be able to make a fresh unit test");

assert_equals( $t->setTarget('punit::TestCase'), $t, "Change to TestCase" );
assert_equals( $t->generateTest(), $t, "Should be able to make a fresh unit test");

assert_equals( $t->setTarget('punit::SkelGen'), $t, "Change to SkelGen" );
assert_equals( $t->generateTest(), $t, "Should be able to make a fresh unit test");

# with hide private...
$t= punit::SkelGen->new('punit::SkelGen', 1, 0);
rename('./punit/t/SkelGenTest.t', './punit/t/SkelGenTest.noprivate.t'); 
assert_equals( $t->generateTest(), $t, "Should be able to make a fresh unit test");

done_testing();


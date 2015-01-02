use strict;
use warnings;

# TRUE and FALSE
use constant::boolean;
use Test::More;
use Test::Assert ':assert';
# test::assert uses Exceptions
use Try::Tiny;

use_ok( 'punit::IOAccess');
my $t= punit::IOAccess->new(0);

assert_isa('punit::IOAccess', $t, "have right object");

assert_true($t->listAPI('punit::IOAccess'), "have data from listAPI");
# print $t->listAPI('punit::IOAccess');

my @t=$t->listAPI('punit::IOAccess');
@t=sort( @t);
assert_deep_equals( \@t, [ 'createTestPath', 'listAPI', 'writeTestFile' ], "have expected list from IOAccess");

@t  = sort( $t->listAPI('punit::IOAccess'));
# make sure nothing blows up if run multiple times...
assert_deep_equals( \@t, [ 'createTestPath', 'listAPI', 'writeTestFile' ], "safe to call three times");

assert_true($t->listAPI('punit::PANDASTYLE'), "have a bad class name");

my $fn="/tmp/1.txt";
my $data="sfsdf\nsgdgdfg\nrgdfgdfgdfg\n";
if ( -f $fn ) { 
	unlink( $fn); 
	diag("Deleted old test results");
}

assert_true($t->writeTestFile($fn, $data), "disk write reported no error" );
assert_raises(['BadFileException'], sub {$t->writeTestFile($fn, $data) } );
diag("pass dup test...");

my $fn="/tmp/t/1.txt";
if ( -f $fn ) { 
	unlink( $fn); 
	diag("Deleted old test results");
}
if ( -f '/tmp/t' ) { 
	unlink( '/tmp/t'); 
	diag("Deleted old test results");
}
assert_true($t->writeTestFile($fn, $data), "disk write reported no error" );
assert_true( -f '/tmp/t');
assert_true( -f '/tmp/t/1.txt');
unlink( $fn); 
unlink( '/tmp/t'); 


assert_raises(['BadFileException'], sub {$t->writeTestFile('/panda/style/dfgfghfhfgh', $data) } );

$fn="/tmp/2.txt";
if ( -f $fn ) { 
	unlink $fn; 
	diag("Deleted old test results");
}
assert_false($t->writeTestFile($fn, ''), "disk write reported no error" );

assert_equals($t->createTestPath('punit::IOAccess'), 'punit/t/IOAccessTest.t');
done_testing();


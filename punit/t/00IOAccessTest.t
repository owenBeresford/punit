use strict;
use warnings;
use diagnostics;

# TRUE and FALSE
use constant::boolean;
use Test::More;
use Test::Assert ':assert';
use Data::Dumper;
# test::assert uses Exceptions
use Try::Tiny ();
# this nut is more messy than i would like
use punit::CodeMunge;
use punit::ClassGen;
BEGIN {
use File::Basename;
push( @INC, dirname(__FILE__)."/Data/");
}
our $DEBUG=1;

use_ok( 'punit::IOAccess');
my $t= punit::IOAccess->new(0, punit::CodeMunge->new( punit::ClassGen->new()));

assert_isa('punit::IOAccess', $t, "have right object");

assert_true($t->listAPI('punit::IOAccess'), "have data from listAPI");
# print $t->listAPI('punit::IOAccess');

my @t=$t->listAPI('punit::CodeMunge');
@t=sort( @t);
print Dumper \@t;
assert_deep_equals( \@t, [ 
'processAssert',  
'processNoTest', 
'setFunction', 
'setPackage', 
], "have expected list from IOAccess");

@t  = sort( $t->listAPI('punit::IOAccess'));
# make sure nothing blows up if run multiple times.. ie leaking anything.
assert_deep_equals( \@t, [ 'createTestPath', 'extractAssert','listAPI', 'writeTestFile'  ], "safe to call three times");

# assert_true($t->listAPI('punit::PANDASTYLE'), "have a bad class name");

my $fn="/tmp/1.txt";
my $data="sfsdf\nsgdgdfg\nrgdfgdfgdfg\n";
if ( -f $fn ) { 
	unlink( $fn); 
	diag("Deleted old test results");
}

my $tt=$t->extractAssert('punit::t::Data::SampleFullStatements');
assert_equals( 3, scalar(keys(%{$tt})),  "Look for asserts in sample file");
my @ttt = values(%{$tt});
@ttt = map {@$_} @ttt;
assert_equals( 9, scalar(@ttt),  "Look for asserts in sample file 2");

assert_true( scalar($t->extractAssert('punit::IOAccess')), "Look for asserts in a file without any");
#try {
#	assert_true( scalar($t->extractAssert('punit::PANDASTYLE')), "Look for asserts in a bad file");
#} catch {
#	diag("CAUGHT missing file ....");
#	assert_true(1);
#};
# have to turn this off, in DEBUG the software doesn't touch the filesystem
$DEBUG=0;

assert_true($t->writeTestFile($fn, $data), "disk write reported no error" );
assert_raises(['BadFileException'], sub {$t->writeTestFile($fn, $data) } );
diag("pass dup test...");

$fn="/tmp/t/1.txt";
if ( -f $fn ) { 
	unlink( $fn); 
	diag("Deleted old test results");
}
if ( -d '/tmp/t' ) { 
	unlink( '/tmp/t'); 
	diag("Deleted old test results");
}
assert_true($t->writeTestFile($fn, $data), "disk write reported no error" );
assert_true( -d '/tmp/t');
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


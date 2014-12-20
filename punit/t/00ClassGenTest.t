use strict;
use warnings;

# TRUE and FALSE
use constant::boolean;
use Test::More;
use Test::Assert ':assert';
# test::assert uses Exceptions
use Try::Tiny;

use_ok( 'punit::ClassGen');
my $t= punit::ClassGen->new();

assert_isa('punit::ClassGen', $t, "have right object");
# I guess these trues should also have regexes attached to them, as they could return an 'empty' string; practically look at the combined one
assert_true($t->getDocs('Funcii'), "We can document 'Funcii'.");
assert_true($t->getSetUp('Funcii'), "We can setUp 'Funcii'.");
assert_true($t->getTearDown('Funcii'), "We can tearDown 'Funcii'.");
assert_true($t->getFunctionOutro('Funcii'), "We can function outro 'Funcii'.");
assert_true($t->getFunctionIntro('Funcii'), "We can function intro 'Funcii'.");
assert_true($t->getPackageIntro('Funcii', 'FunciiTest'), "We can package intro 'Funcii'.");
assert_true($t->getPackageOutro('Funcii'), "We can package outro 'Funcii'.");

my $okay =0;
my $perl =$t->getAll('Funcii', 'FunciiTest', ('I_wanna_get', 'get_down', 'get_get_down'));
assert_true($perl, "We should have a class");
try {
	eval($perl);
	$okay=1;
} catch {
	assert_false( $@, "ERROR when compiled: $_");
} finally {
	assert_true($okay, "Generated code compiles, w00t!");
	done_testing();
}


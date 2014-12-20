use strict;
use warnings;

{
package testClass;

sub new {
	my ($caller) = @_;
	my $class = ref($caller) || $caller;

	my $hash  = { mood=>'green' };
	bless( $hash, $class);
	return $hash;
}

}

# TRUE and FALSE
use constant::boolean;
# In previous use of test::assert I never got the message attach to the test condition on test failure.
# I am writing this on Perl 5.18.2, that was Perl 5.10.2


use Test::Assert ':assert';
use Test::More;
#use Test::Exception;
# test::assert uses Exceptions
use Try::Tiny;

try {
	diag("any messages should be prefixed with an explaination message");
# assert_equals( value1 : Defined, value2 : Defined, message : Str = undef )
	assert_equals(1, 1, "You should not be able to see this message.");
	assert_true(1, "You should not be able to see this message.");

	my $tm=testClass->new();
	assert_isa( 'testClass', $tm, "You should not be able to see this message.");
	assert_false(1, "**Error text reported.**");

} catch {
	warn $_;
};

{
package ANormalUse;
use base 'Test::Assert';

sub new {
	my ($caller) = @_;
	my $class = ref($caller) || $caller;

	my $hash  = { mood=>'green' };
	bless( $hash, $class);
	return $hash;		
}

sub run {
	my( $self )= @_;

	try {
		$self->assert_equals(1, 1, "You should not be able to see this message.");
		$self->assert_true(1, "You should not be able to see this message.");

		my $tm=testClass->new();
		$self->assert_isa( 'testClass', $tm, "You should not be able to see this message.");
		$self->assert_false(1, "**Error text reported.**");

	} catch {
		warn @_;
	};
}

}

my $t = ANormalUse->new();
$t->run();


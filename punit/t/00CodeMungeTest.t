#!/usr/bin/perl -I/home/owen/punit
# I'm making the testee object in lexical scope (not part of the $self which is called what?)
# Replace all the XXX with your code
use strict;
use warnings;
# use diagnostics -verbose;

{
package punit::t::MockPPIToken;
my $line_number;
my $content;

	sub new {
		my ($caller, $a, $b)  		= @_;
		my $class = ref($caller) || $caller;

		$line_number=$b;
		$content=$a;
		return bless({}, $class);
	}

	sub line_number { return $line_number; }
	sub content { return $content; }

}



{
package punit::t::CodeMungeTest;
use punit::TestCase;
use base 'punit::TestCase';
use utf8;
use Data::Dumper;  # while testing the test case, you are bound to need this...
use punit::ClassGen;
use Test::More;
use Test::Exception;
use Try::Tiny ();
use punit::CodeMunge;
# use Exception classes etc.

my $obj = undef();

# use the new defined in base... :-)
# if you want to override still run the original one

sub setUp {
	my $self 	= shift;

# You must edit to set param, enable line at the at point
	$obj	= punit::CodeMunge->new( punit::ClassGen->new() );
	$obj->setPackage('AClass');
	$obj->setFunction('funcA');

}

sub tearDown {
	my $self  = shift;
# XXX
}

sub testsetFunction {
	my ($self)		= @_;

	skip(0);
	LAST:
}

sub testsetPackage {
	my ($self)		= @_;

	skip(0);
	LAST:
}

sub testprocessNoTest {
	my ($self)		= @_;

	my $list={};
	my $a=punit::t::MockPPIToken->new("# \@NOTEST \"A TEST\"", 42); 
	my $ret=$obj->processNoTest($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );

	$a=punit::t::MockPPIToken->new("# \@NOTEST \"B TEST\"", 42); 
	$obj->setFunction('funcB');
	$ret=$obj->processNoTest($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==2 );
	assert_true( defined( $list->{funcA}) );
	assert_true( defined( $list->{funcB}) );
	assert_true( !defined( $list->{funcC}) );

	try {
		$a=punit::t::MockPPIToken->new("# \@NOTEST \"A TEST\"", 42); 
		$obj->setFunction('funcA');
		$ret=$obj->processNoTest($a, $list);
		assert_false( "You cant get here");
	} catch {
		assert_true(1);
	}
}


sub testprocessAssert {
	my ($self)		= @_;

	my $list={};
	my $countA=0;

	my $a=punit::t::MockPPIToken->new("# \@assert \$obj->funcA() == 0 ", 42); 
	my $ret=$obj->processAssert($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );
	$countA =scalar( @{$list->{funcA}} );
	assert_same( 1, $countA );

	$a=punit::t::MockPPIToken->new("# \@assert \$obj->funcB() == 0 ", 42); 
	$ret=$obj->processAssert($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );
	assert_true( defined( $list->{funcB}) );
	$countA =scalar( @{$list->{funcA}} );
	assert_same( 1, $countA );

	$a=punit::t::MockPPIToken->new("# \@assert \$obj->funcA() === 0 ", 42); 
	$ret=$obj->processAssert($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );
	$countA =scalar( @{$list->{funcA}} );
	assert_same( 2, $countA );

	$a=punit::t::MockPPIToken->new("# \@assert \$obj->funcA() !== 0 ", 42); 
	$ret=$obj->processAssert($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );
	$countA =scalar( @{$list->{funcA}} );
	assert_same( 3, $countA );

	$a=punit::t::MockPPIToken->new("# \@assert \$obj->funcA() isa 'TESTclass' ", 42); 
	$ret=$obj->processAssert($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );
	$countA =scalar( @{$list->{funcA}} );
	assert_same( 4, $countA );

	$a=punit::t::MockPPIToken->new("# \@assert \$obj->funcA() >= 0 ", 42); 
	$ret=$obj->processAssert($a, $list);
	assert_true( $ret==0);
	assert_true( scalar(keys( $list))==1 );
	assert_true( defined( $list->{funcA}) );
	$countA =scalar( @{$list->{funcA}} );
	assert_same( 5, $countA );
}

}

# add the "if run from prove, execute... "
unless(caller()) {
	my $t		= punit::t::CodeMungeTest ->new();
	$t->run();
}

1;


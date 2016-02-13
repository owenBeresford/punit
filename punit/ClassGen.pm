use strict;
use warnings;

=for comment
This class holds code snippets that get assembled into a unit test class.
It has a lot of small functions so it can be sub-classed.

ASSERT: Some people have weird ideas on how to indent, please don't.  Please perltidy.

=cut

{
package punit::ClassGen;
use Exporter 'import';
use version;
our @EXPORT = ();
our @EXPORT_OK = qw(getFunctionOutro getFunctionIntro getPackageIntro getPackageOutro getSetUp getTearDown getDocs getAll );
our $VERSION = '0.1.6';
use Data::Dumper;

sub new {
	my ($caller) = @_;
	my $class = ref($caller) || $caller;

	my $hash  = { };
	bless( $hash, $class);
	return $hash;
}

sub getFunctionOutro {
	my ($self, $func ) = @_;
	my $out		=' ';

	return $out;
}

sub getFunctionIntro {
	my ($self, $func ) = @_;
	my $out		=' ';

	return $out;
}

sub getTestCode {
	my ($self, $object, $func, $args, $test, $value, $comment )= @_;
	my $op={
		'=='=>'assert_equals',
		'!='=>'assert_not_equals',
		'==='=>'assert_deep_equals',
		'!=='=>'assert_deep_not_equals',
		'isa'=>'assert_isa',
		'!isa'=>'assert_not_isa',
		'>'=>'assert_true',
		'>='=>'assert_true',
		'<'=>'assert_true',
		'<='=>'assert_true',
		'noTest' => 'skip',
	};
	my $exec=undef();

	if($test eq '>' || $test eq '<' || $test eq '>=' || $test eq '<=') {
		$exec=$op->{ $test }."(\$obj->$func($args) $test $value, $comment);";
	} else {
		$exec=$op->{ $test }."(\$obj->$func($args), $value, $comment);";
	}

	return $exec;
}

sub getPackageIntro {
	my ($self, $name, $class ) = @_;
	my $sname	=$name;
	$sname		=~ s/::/\//g;

	my $out		=<<EOPERL;
#!/usr/bin/perl -I/home/owen/punit
# I'm making the testee object in lexical scope (not part of the \$self which is called what?)
# Replace all the XXX with your code
use strict;
use warnings;

{
package $class;
use punit::TestCase;
use base 'punit::TestCase';
use utf8;
use Data::Dumper;  # while testing the test case, you are bound to need this...
use Test::More;
use Test::Exception;
use $name;
# use Exception classes etc.

my \$obj = undef();

# use the new defined in base... :-)
# if you want to override still run the original one

EOPERL

	return $out;
}

sub getPackageOutro {
	my ($self, $class ) = @_;

	my $out		=<<EOPERL;
}

# add the "if run from prove, execute... "
unless(caller()) {
	my \$t		= $class ->new();
	\$t->run();
}
1;

EOPERL

	return $out;
}

sub getSetUp {
	my ($self, $name) = @_;
	
	my $out		=<<EOPERL;
sub setUp {
	my \$self 	= shift;

# You must edit to set param, enable line at the at point
# \$obj	= $name ->new( );
# XXX
}

EOPERL

	return $out;
}

sub getTearDown {
	my ($self)  = @_;
	my $out		=<<EOPERL;
sub tearDown {
	my \$self  = shift;
# XXX
}

EOPERL
	return $out;
}
	
sub getDocs {
	my ($self, $func) = @_;
	my $out		=<<EOPERL;
=begin comment
Test for $func ~ no annotations, can't tag this test

\@author: oab1 <owen\@iceline.ltd.uk> 
\@return null
=cut

EOPERL
	return $out;
}


sub getAll {
	my ($self, $name, $class, $reference) = @_;
	my %list	=%{$reference};
	my $out		='';
	$out		.= $self->getPackageIntro($name, $class); 
	$out		.= $self->getSetUp($name); 
	$out		.= $self->getTearDown($name); 
	for my $func (keys %list) {
# not allowed param to these functions
		$out	.=<<EOPERL;
sub test$func {
	my (\$self)		= \@_;

EOPERL
	
		$out	.= $self->getFunctionIntro($func);  
		my @annoy=@{$list{$func}};
		$out    .= "\t".join("\n\t", @annoy) ."\n";
		$out	.= $self->getFunctionOutro($func);  
		$out	.=<<EOPERL;

}

EOPERL
	}
	$out		.=$self->getPackageOutro($class); 
	return $out;
}


}
1;

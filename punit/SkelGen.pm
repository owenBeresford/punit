#!/usr/bin/env perl
use strict;
use warnings;
our $DEBUG=0;
our $VERSION='0.1.2';

sub HELP_MESSAGE {
    my ( $fh, $package, $version, $switches ) = @_;

# he arguments are the output file handle, the name of option-processing package, its version, and the switches string
    print $fh <<EOTEXT;

Param for SkelGen
(im still not sure that this is the correct structure for CLI access)

   -i <package>  : input package name
   -h            : display this help
   -d            : run in DEBUG (output & doesn't write files)
   -p            : include private functions

This will make test scripts in the relevant 't' sub directory.  Will make 't' if necessary.  This is currently too picky about `pwd`, but this will change.
If not obvious, you MUST HAVE WRITE ACCESS.

If you have non-standard code layout, please refer to the manualloader.example.pl

EOTEXT

}



{
package punit::SkelGen;
use punit::IOAccess;
use punit::ClassGen;
use punit::CodeMunge;
use Exporter 'import';
use version;
use Data::Dumper;

our @EXPORT = ();
our @EXPORT_OK = qw( generateTest );
our $VERSION = '0.1.3';

sub new {
	my ($class, $inCls, $private, $db) = @_;

	my $self={
		debug	=>$db || 0,
		inClass =>$inCls,
	# I don't need inFile, the Perl intepreter will fix that
		outFile =>'',
		outClass=>'',
		gen		=>punit::ClassGen->new()
			};
	my $t=punit::CodeMunge->new($self->{gen} );
	$self->{IO}=punit::IOAccess->new($private, $t);
	bless($self, $class);

	$self->{outClass}=$self->_getOutputClass($inCls); 
	$self->{outFile}=$self->{IO}->createTestPath($inCls); 
	return $self;
}

sub generateTest {
	my ($self ) = @_;
	
	my @decls	= $self->{IO}->listAPI($self->{inClass});
	my $assert	= $self->{IO}->extractAssert($self->{inClass});
	my %decls2  = ();
	foreach my $s (@decls) {
		if(defined($assert->{$s})) {
			$decls2{$s}=$assert->{$s};
		} else {
			$decls2{$s}=["# fillin this test, no assert provided."];
		}
	}
	my $raw		= $self->{gen}->getAll($self->{inClass}, $self->{outClass}, \%decls2);

	if($self->{debug}) {
		return $raw;
	} else {
		$self->{IO}->writeTestFile($self->{outFile}, $raw ); 	
	}
	return $self;
} 

sub setTarget {
	my ($self, $inCls ) = @_;
	
	$self->{inClass}=$inCls;
	$self->{outClass}=$self->_getOutputClass($inCls); 
	$self->{outFile}=$self->{IO}->createTestPath($inCls); 
	return $self;
}

sub _getOutputClass {
	my ($self, $inCls ) = @_;

	my @t		=split('::', $inCls);
	my $class	=pop( @t);
	push( @t, 't');
	push( @t, $class."Test");
	return join('::', @t); 
}

}

unless(caller()) {
	die("Must supply some param, try --help\n") unless @ARGV;

	use Getopt::Std;
    $Getopt::Std::STANDARD_HELP_VERSION = 1;
	my %options	= ();
	getopts("i:hdp:",\%options);
	if($options{d}) {
		$main::DEBUG++;
		print("Set DEBUG flag.\n" );	
	}
	if($options{h}) {
		HELP_MESSAGE(*STDOUT);
		exit(0);
	}
	
	my $t		= punit::SkelGen->new($options{i}, $options{p}, $options{d});
	my $ret		= $t->generateTest();
	print $ret  if($main::DEBUG);
}
1;

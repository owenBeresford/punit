#!/usr/bin/env perl
use strict;
use warnings;
our $DEBUG=0;

{
package punit::SkelGen;
use punit::IOAccess;
use punit::ClassGen;
use Exporter 'import';
use version;

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
		IO		=>punit::IOAccess->new($private),
		gen		=>punit::ClassGen->new()
			};
	bless($self, $class);

	$self->{outClass}=$self->_getOutputClass($inCls); 
	$self->{outFile}=$self->{IO}->createTestPath($inCls); 
	return $self;
}

sub generateTest {
	my ($self ) = @_;
	
	my @decls	= $self->{IO}->listAPI($self->{inClass});
	my $raw		= $self->{gen}->getAll($self->{inClass}, $self->{outClass}, @decls);

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
	use Getopt::Std;
	my %options	= ();
	getopts("o:i:hd",\%options);
	if($options{d}) {
		$DEBUG++;	
	}
	
	my $t		= punit::SkelGen->new($options{'i'}, 0, $options{'d'});
	my $ret		= $t->generateTest();
	print $ret  if($DEBUG);
}
1;

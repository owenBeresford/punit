use strict;
use warnings;

{
package punit::TestCase;
use Test::More ;
use Test::Exception;
use punit::IOAccess ();
use Scalar::Util ();
use Exporter 'import';
use version;
use Data::Dumper;  # while testing the test case, you are bound to need this...

use Exception::Class (
		'Exception', 

      'VirtualBaseException' => {
          isa         => 'Exception',
          description => 'Exception for people using an ancestor class directly, not an impl.'
      },
);

our @EXPORT = ();
our @EXPORT_OK = qw( run );
our $VERSION = '0.1.2';

sub new {
 	my ($class, $clone) = @_;

	my $self =  {
				obj => undef(), 
				};
	if($clone && Scalar::Util::blessed( $clone) && $clone->isa(__PACKAGE__)) {
		for my $key (keys %{$clone}) {
			$self->{$key}=$clone->{$key};
		}
	}
	bless( $self, ref($clone) || $class); 
	return $self;
}

sub run {
	my ($self)	= @_;
	my $module	= ref($self);
	if($module eq __PACKAGE__) {
		VirtualBaseException->throw( "No, don't TestCase->run, use a sub-class with something to test ;-)");
	}

	my $io		= punit::IOAccess->new();
	my @funcs 	= $io->listAPI(ref($self) );

	diag("I am module: $module -> run()\n");
	$self->setUp();
	foreach my $func (@funcs ) {
#       meta is for Moose
		if($func eq 'setUp' || $func eq 'tearDown' || 
				$func eq 'meta' || $func eq 'new' ) {
			next;
		}
		my $tmp = $self->new($self);	
		diag("\tcurrently running $func()\n");
		$tmp->$func();
		$tmp->tearDown();
	}

}


}
1;

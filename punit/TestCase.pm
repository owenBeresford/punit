use strict;
use warnings;

{
package punit::TestCase;
use Test::Assert;
use Test::More;
use base 'Test::Assert';
use punit::IOAccess;
use Scalar::Util;

use Exception::Class (
		'Exception', 

      'VirtualBaseException' => {
          isa         => 'Exception',
          description => 'Exception for people using an ancestor class directly, not an impl.'
      },
);

sub new {
 	my ($class, $clone) = @_;

	my $self =  {
				obj => undef(), 
				};
	if($clone && Scalar::Util::blessed( $clone) && $clone->isa(__PACKAGE__)) {
		$self->{obj}=$clone->{obj};
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

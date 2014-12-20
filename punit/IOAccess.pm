use strict;
use warnings;
use 5.10.2;

{
package punit::IOAccess;
use Symbol::Table;
use Try::Tiny ();
use Exception::Class (
		'BaseException',

      'BadFileException' => {
          isa         => 'BaseException',
          description => 'Exception being unable to make valid PM file.'
      },
);

	sub new {
		my ($caller, $priva)  		= @_;
		my $class = ref($caller) || $caller;

		my $hash 			= { private =>$priva };
		bless($hash, $class);
		return $hash;  # currently no class vars
	}

# this is a point of isolation, the previous MVP edition needed alo of hacks 
# to work
# $class is a string, not an object
	sub listAPI {
		my ($self, $class) = @_;
		my @out;
		my $st	=Symbol::Table->New('CODE', $class);

		for my $func (keys %{$st}) {
			print "listAPI: looking at '$func'." if($main::DEBUG);

print("The private functions are being filtered by the Symbol::Table library WW $func, ".$self->{private}." ". $func =~ m/^_/ );
			
			next if ($func eq 'new');
			next if (!$self->{private} && $func =~ m/^_/);

# expect to inject hacks here...
			push(@out, $func);
		}
		
		if(wantarray() ) { return @out; }
		else 			 { return \@out; }
	}


	sub writeTestFile {
		my ($self, $name, $data) = @_;
		
		if( -f $name ) {			
			print "Can't create file '$name', it already exists." if($main::DEBUG);
			BadFileException->throw("Can't create file '$name', it already exists.");
		}
		open( OUTPUT, ">:utf8", $name ) 
			or BadFileException->throw("Can't create file '$name', as $!"); 
		print OUTPUT "$data\n";
		close(OUTPUT);
		return length($data);
	}

	sub createTestPath {
		my ($self, $name) = @_;

		my @tmp 	= split('::', $name);
		$name		= pop @tmp;
		$name		.="Test.t";
		push( @tmp, "t");
		push( @tmp, $name);
		return join('/', @tmp);
	}

}
1;


use strict;
use warnings;
use 5.10.2;

{
package punit::IOAccess;
use Class::Inspector;
use Try::Tiny ();
use Exporter 'import';
use version;
use B qw( svref_2object );
use Data::Dumper;

use Exception::Class (
		'BaseException',

      'BadFileException' => {
          isa         => 'BaseException',
          description => 'Exception being unable to make valid PM file.'
      },
);

our @EXPORT = ();
our @EXPORT_OK = qw( listAPI writeTestFile createTestPath );
our $VERSION = '0.1.1';

	sub new {
		my ($caller, $priva)  		= @_;
		my $class = ref($caller) || $caller;

		my $hash 			= { private =>$priva || 0 };
		bless($hash, $class);
		return $hash;  # currently no class vars
	}

# this is a point of isolation, the previous MVP edition needed alo of hacks 
# to work
# $class is a string, not an object
	sub listAPI {
		my ($self, $class) = @_;
		my @out;
#		my $methods = Class::Inspector->methods( $class );
		my $methods = $self->_list_nonimported_subs($class); 


#		my $parent = '';
#		my $tmp = "\$parent = \$".$class."::ISA[ scalar(@".$class."::ISA) ] || undef(); ";
#		eval($tmp);	
#print "Whaqt is parent? ". Dumper $parent."\n";

		for my $func (@$methods) {
			print "listAPI: looking at '$func'." if($main::DEBUG);
		
#	print "can \$parent do $func? ".($parent->can($func)?"yes\n":"no\n");
#  if($self->SUPER->can($func)) { print "method $func exists in ancestor.\n"; }
# discard functions that are defined in the parent or higher classes.
# doesn't cover situation where a subclass overrides a parents definition.
#			next if ($parent && $parent->can($func));
			next if ($func eq 'new');
			next if (!$self->{private} && $func =~ m/^_/);

# expect to inject hacks here...
			push(@out, $func);
		}
		
		if(wantarray() ) { return @out; }
		else 			 { return \@out; }
	}

# http://stackoverflow.com/questions/12504744/perl-list-subs-in-a-package-excluding-imported-subs-from-other-packages
	sub _list_nonimported_subs {
		my ($self, $pkg_name) = @_;
		my $pkg = do { no strict 'refs'; *{ $pkg_name . '::' } };

		my @nonimported_subs=();
		for my $name (keys %$pkg) {
			my $glob = $pkg->{$name};
			my $code = *$glob{CODE}
			or next;

			my $cv = svref_2object($code);
			my $orig_pkg_name = $cv->GV->STASH->NAME;
			next if $orig_pkg_name ne $pkg_name;

			push @nonimported_subs, $name;
		}

		if(wantarray() ) { return @nonimported_subs; }
		else 			 { return \@nonimported_subs; }
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


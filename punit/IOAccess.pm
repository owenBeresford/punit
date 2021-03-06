use strict;
use warnings;
use 5.10.2;

{
package punit::IOAccess;
use Try::Tiny ();
use Exporter 'import';
use version;
use feature 'current_sub';
use PPI;
use B qw( svref_2object );
use Data::Dumper;
use Class::Load qw(is_class_loaded);
use Module::Util qw( module_fs_path);
use feature qw/switch/; 

use Exception::Class (
	'BaseException',

	'BadFileException' => {
		isa         => 'BaseException',
		description => 'Exception being unable to make valid PM file.'
	},
	'BadParamException' => {
		isa         => 'BaseException',
		description => 'Exception code feed wrong data.'
	},
);

our @EXPORT = ();
our @EXPORT_OK = qw( listAPI writeTestFile createTestPath extractAssert );
our $VERSION = '0.2.1';

	sub new {
		my ($caller, $priva, $munge)  		= @_;
		my $class = ref($caller) || $caller;

		my $hash 			= { private =>$priva || 0, munge=>$munge };
		bless($hash, $class);
		return $hash;  
	}

# this is a point of isolation, the previous MVP edition needed alo of hacks 
# to work
# $class is a string, not an object
	sub listAPI {
		my ($self, $class) = @_;
		if( ref $class ne "") {
			BadParamException->throw("Can't map an object at present, DO NOT USE IN PRODUCTION CODE");
		} 
		my @out;
		my $fl_name	= module_fs_path($class);
		
		if( ! -f $fl_name) {
			$fl_name =~ s/\.pm$/.t/;
			if( ! -f $fl_name) {
				BadFileException->throw("Can't load package $class $fl_name. \n");
			}
		}

		if(!is_class_loaded($class)) {
			eval("use $class;"); 
			if( scalar $@) { 
				BadFileException->throw("Can't load package $class. \n\n$@\n");
			}
		}

		my $doc = PPI::Document->new($fl_name);
		my $methods= $doc->find('PPI::Statement::Sub');
		for my $func (@{$methods} ) {
			my $name=$func->schild(1)->content;
			print "looking at '$name'.\n" if($main::DEBUG);
		
			next if ($name eq 'new');
			next if (!$self->{private} && $name =~ m/^_/);
# some people put private classes in the same file as the published module.  
# need to strip these out, or the test crashes
			next if ($self->_getClass($func) ne $class);

# expect to inject hacks here...
			push(@out, $name);
		}
		if(wantarray() ) { return @out; }
		else 			 { return \@out; }
	}

	sub _getClass {
		my ($self, $codePoint) = @_;
		my $breakOut=100;		
		my $t;

		while($codePoint->class ne 'PPI::Statement::Package' &&
				$codePoint->class ne 'PPI::Document') {

			if(	$codePoint->class eq 'PPI::Structure::Block'  && 
				$codePoint->schild(0)->class() eq 'PPI::Statement::Package') {
				$t=$codePoint->schild(0)->content;
				$t =~ s/^package[ \t]+//;
				$t =~ s/;$//;
				return $t;
			}
			$codePoint = $codePoint->parent();

			$breakOut--;
			if($breakOut==0) { 
				warn "Statement depth >100.  Assume error."; 
				return undef();
			}
		}

		$t=$codePoint->content;
		$t =~ s/^package[ \t]+//;
		$t =~ s/;$//;
		return $t;
	}

	sub extractAssert {
		my ($self, $pkg_name) = @_;
		try {
			my $fl_name	= module_fs_path($pkg_name);
			if( ! -f $fl_name) {
				BadFileException->throw("Can't load package $fl_name.");
			}

			my $doc = PPI::Document->new($fl_name);
			my $list={};
			if (!( $doc->find_any('PPI::Token::Pod') || 
					$doc->find_any('PPI::Token::Comment') )) {
				print "File '$pkg_name' contains no docs.\n" if($main::DEBUG);
				return [];
			}
			$self->{munge}->setPackage($pkg_name);

			my $comments = $doc->find( 'PPI::Token::Comment');
			foreach my $c ( @{$comments}) {
				my $tt=$c->snext_sibling();
				if($tt and $tt->class eq "PPI::Statement::Sub") {
					$self->{munge}->setFunction($tt->name);
				} else {
					$self->{munge}->setFunction('XXXXX');
					print "Unable to sniff what function this is attached to.\n" if($main::DEBUG);
				}

				if( $c->content =~ m/\@assert/i ) {
					print "Running assert parsing at ".$c->line_number.".\n" if($main::DEBUG);
					$self->{munge}->processAssert($c, $list);
				}
				if( $c->content =~ m/\@NOTEST/i  ) {
					$self->{munge}->processNoTest($c, $list);
				}
			}
			$doc=undef();
			$comments=undef();
			return $list; 

		} catch {
			print("Unknown file '$pkg_name' - shouldn't happen in real use as trapped else where...\n");
			return [];
		}
	}

	sub writeTestFile {
		my ($self, $name, $data) = @_;
		
		if( -f $name ) {			
			print "Can't create file '$name', it already exists.\n" if($main::DEBUG);
			BadFileException->throw("Can't create file '$name', it already exists.");
		}
		my @bits		=split('/', $name);
		pop @bits; # want the array, not the scalar, so must be separate 
		my $dirname		=join('/', @bits); 
		if( ! -d $dirname ) {
			if($main::DEBUG) {
				print "Can't create file '$name', it already exists.\n"; 
			} else {
				mkdir $dirname or BadFileException->throw("Unable to make 't' directory... $dirname ".`pwd`);
			}
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

# http://stackoverflow.com/questions/12504744/perl-list-subs-in-a-package-excluding-imported-subs-from-other-packages
	sub _list_nonimported_subs {
		my ($self, $pkg_name) = @_;
		my $pkg = do { no strict 'refs'; *{ $pkg_name . '::' } };

		my @nonimported_subs=();
		for my $name (keys %$pkg) {
			my $glob = $pkg->{$name};
# drop all non CODE types.
			my $code = *$glob{CODE} or next;

			my $cv = svref_2object($code);
			my $orig_pkg_name = $cv->GV->STASH->NAME;
# compare the package name
			next if $orig_pkg_name ne $pkg_name;

			push @nonimported_subs, $name;
		}

		if(wantarray() ) { return @nonimported_subs; }
		else 			 { return \@nonimported_subs; }
	}

}
1;



use strict;
use warnings;
use 5.10.2;

{
package punit::IOAccess;
use Try::Tiny ();
use Exporter 'import';
use version;
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
);

our @EXPORT = ();
our @EXPORT_OK = qw( listAPI writeTestFile createTestPath extractAssert );
our $VERSION = '0.2.1';

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
		my $fl_name	= module_fs_path($class);
		if( ! -f $fl_name) {
			print "Invalid module name '$class'.\n";
			return [];
		}

		if(!is_class_loaded($class)) {
			eval("use $class;"); 
			if( scalar $@) { 
				BadFileException->throw("Can't load package $class. \n\n$@\n");
			}
		}

		my $methods = $self->_list_nonimported_subs($class); 

		for my $func (@$methods) {
			print "listAPI: looking at '$func'.\n" if($main::DEBUG);
		
			next if ($func eq 'new');
			next if (!$self->{private} && $func =~ m/^_/);

# expect to inject hacks here...
			push(@out, $func);
		}
		
		if(wantarray() ) { return @out; }
		else 			 { return \@out; }
	}

	sub extractAssert {
		my ($self, $pkg_name) = @_;
		try {
			my $fl_name	= module_fs_path($pkg_name);
			if( ! -f $fl_name) {
				print "Invalid module name '$pkg_name'.\n";
				return [];
			}

			my $doc = PPI::Document->new($fl_name);
			my $list={};
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
			};

			if (!( $doc->find_any('PPI::Token::Pod') || 
					$doc->find_any('PPI::Token::Comment') )) {
				print "File '$pkg_name' contains no docs.\n";
				return [];
			}

			my $comments = $doc->find( 'PPI::Token::Comment');
			foreach my $c ( @{$comments}) {
				if( $c->content =~ m/\@assert/i  ) {
					my @match= $self->_match($pkg_name, $c->content, $c->line_number);
					if($#match==0) {
						print $c->content." doesn't match anything...\n";
						next;
					}

					my $exec=undef();
					my ($object, $func, $args, $test, $value, $comment) = @match;
					if($test eq '>' || $test eq '<' || $test eq '>=' || $test eq '<=') {
						$exec=$op->{ $test }."(\$obj->$func($args) $test $value, $comment);";
					} else {
						$exec=$op->{ $test }."(\$obj->$func($args), $value, $comment);";
					}

					if(defined($list->{$func})) {
						my $length=$#{$list->{$func}};
						$length++;
						$list->{$func}->[$length]=$exec;

					} else {
						$list->{$func}=[];
						$list->{$func}->[0]=$exec;
					}

				}
			}
			$doc=undef();
			$comments=undef();
			return $list; 

		} catch {
			print("unknown file '$pkg_name' - shouldnt happen in real use...");
			return [];
		}
	}


	sub _match {
		my ($self, $package, $str, $line) = @_;
		my $match;

		$match=($str =~ m/^[# \*\t]*\@assert[ \t]+(\$[a-zA-Z0-9_]+)->([a-zA-Z0-9_]+)\(([^)]*)\)[ \t]*([!=><isa]+)[ \t]*([^ ]+)[ \t]+("[a-zA-Z0-9 '"!£\$%\^&*\(\)]+")/);
		return ($1, $2, $3, $4, $5, $6) if($match>0) ;

		$match=($str =~ m/^[# \*\t]*\@assert[ \t]+(\$[a-zA-Z0-9_]+)->([a-zA-Z0-9_]+)\(([^)]*)\)[ \t]*([!=><isa]+)[ \t]*(.+)/);
		return ($1, $2, $3, $4, $5, "\"".$package."#".$line."\"") if($match>0) ;

		warn "ADD MORE CODE";
		return [];
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

	sub writeTestFile {
		my ($self, $name, $data) = @_;
		
		if( -f $name ) {			
			print "Can't create file '$name', it already exists." if($main::DEBUG);
			BadFileException->throw("Can't create file '$name', it already exists.");
		}
		my @bits		=split('/', $name);
		pop @bits; # want the array, not the scalar, so must be separate 
		my $dirname		=join('/', @bits); 
		if( ! -d $dirname ) {
			if($main::DEBUG) {
				print "Can't create file '$name', it already exists."; 
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

}
1;


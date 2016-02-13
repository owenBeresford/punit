use strict;
use warnings;
use 5.10.2;

{
package punit::CodeMunge;
use version;
use PPI;
use Data::Dumper;

use Exception::Class (
	'BaseException',

);

our @EXPORT = ();
our @EXPORT_OK = qw( setFunction setPackage processAssert processNoTest );
our $VERSION = '0.2.1';

	sub new {
		my ($caller, $gen)  		= @_;
		my $class = ref($caller) || $caller;

		my $hash 			= { gen=>$gen, package=>'', function=>'' };
		bless($hash, $class);
		return $hash;  # currently no class vars
	}

	sub setFunction {
		my ($self, $func) = @_;
		$self->{function}=$func;
	}

	sub setPackage {
		my ($self, $p) = @_;
		$self->{package}=$p;
	}

# maybe move this line parsing to PPI as well.
# problem is, if I did that I would have better grasp in each structure, but not the values
# my current approach loudly tells you when it gets an unknown test line.
	sub processAssert {
		my ($self, $chunk, $list) = @_;
		my @match=[];
		my $count=0;

# @assert $obj->funcC() === $obj "a useful comment on what the test does"
#	my ($self, $object, $func, $args, $test, $value, $comment )= @_;
		$count=($chunk->content =~ m/^[# \*\t]*\@assert[ \t]+(\$[a-zA-Z0-9_]+)->([a-zA-Z0-9_]+)\(([^)]*)\)[ \t]*([!=><isa]+)[ \t]*([^ ]+)[ \t]+("[a-zA-Z0-9 '"!£\$%\^&*\(\)]+")/);
		@match=($1, $2, $3, $4, $5, $6) if($count>0) ;

		if($count ==0 ){
			$count=($chunk->content =~ m/^[# \*\t]*\@assert[ \t]+(\$[a-zA-Z0-9_]+)->([a-zA-Z0-9_]+)\(([^)]*)\)[ \t]*([!=><isa]+)[ \t]*(.+)/);
			@match= ($1, $2, $3, $4, $5, "\"".$self->{package}."#".$chunk->line_number."\"") if($count>0) ;
		}

		if($count ==0 ){
			$count=($chunk->content =~ m/^[# \*\t]*\@assert[ \t]+\(([^)]*)\)[ \t]*([!=><isa]+)[ \t]*(.+)[ \t]+("[a-zA-Z0-9 '"!£\$%\^&*\(\)]+")/);
			@match= ( $self->{package}, $self->{function}, $1, $2, $3, $4) if($count>0) ;
		}
	
		if($count ==0 ){
			$count=($chunk->content =~ m/^[# \*\t]*\@assert[ \t]+\(([^)]*)\)[ \t]*([!=><isa]+)[ \t]*(.+)/);
			@match= ($self->{package}, $self->{function}, $1, $2, $3, "\"".$self->{package}."#".$chunk->line_number."\"") if($count>0) ;
		}

		if($#match==0) {
			warn "ADD MORE CODE";
			print $chunk->content." doesn't match anything...\n" if($main::DEBUG);
			return;
		}
		my $exec=$self->{gen}->getTestCode(@match);
		return $self->_insert(\@match, $exec, $list);
	}

	sub processNoTest {
		my ($self, $chunk, $list) = @_;
		
		my $t=($chunk->content =~ m/^[# \*\t]*\@NOTEST[ \t]+("[a-zA-Z0-9 '"!£\$%\^&*\(\)]+")/);
		my @match;
		@match=[ $self->{package}, $self->{function}, '', 'noTest', '', $1 ] if ($t>0);
		@match=[ $self->{package}, $self->{function}, '', 'noTest', '', "No comment entered" ] if ($t==0);
		my $exec=$self->{gen}->getTestCode(@match);
		return $self->_insert(\@match, $exec, $list );
	}

	sub _insert {
		my ($self, $match, $exec, $list) = @_;

		my $func=@{$match}[1];
		if(defined($list->{$func})) {
			my $length=$#{$list->{$func}};
			$length++;
			$list->{$func}->[$length]=$exec;

		} else {
			$list->{$func}=[];
			$list->{$func}->[0]=$exec;
		}
		return 0;
	}
	
}
1;


use strict;
use warnings;
use 5.10.2;

{
package punit::t::Data::SampleFullStatements;

our @EXPORT = ();
our @EXPORT_OK = qw( funcA funcB funcC );
our $VERSION = '0.1.0';

# new ~ bither blither 'contor
# blither
# no @ assert for contors, thats silly
	sub new  {
		# blither...
		return bless(__PACKAGE__, {});
	}

# funcA ~ blither blither
# remember this is test code, it doesn't do anything
# @param fhfhfhfh
# @assert $obj->funcA() == 0
# @assert $obj->funcA(666) == 666
	sub funcA {
		return 0;
	}

# funcB ~ blither blither
# @assert $obj->funcB('ff') == 'BORING'
# @assert $obj->funcB('GREEN') == 'BORING'
# @assert $obj->funcB('green') == 'GREEN'
# @assert $obj->funcB('green', 'blue') == 'GREEN'
# @assert $obj->funcB('blue', 'green') == 'BORING'
	sub funcB {
		my ($self, $type)=@_;

		if($type eq 'green'){
			return "GREEEN";
		} else {
			return 'BORING';
		} 
	}

# funcC ~ blither blither
# remember this is test code, it doesn't do anything
# @assert $obj->funcC() === $obj
# @assert $obj->funcC() === $obj "a useful comment on what the test does"
	sub funcC {
		return $_[0];
	}

}


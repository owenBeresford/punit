use strict;
use warnings;
use 5.10.2;

{
package punit::t::Data::SampleNoTest;

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
# @NOTEST "i think this function is too simple to test"
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
# @NOTEST
	sub funcC {
		return $_[0];
	}

}


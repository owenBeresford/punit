# No i am not trying to be clever with this name.
use strict;
use warnings;

# TRUE and FALSE
use constant::boolean;
use Test::More;
use Test::Assert ':assert';
# test::assert uses Exceptions
use Try::Tiny;

use_ok( 'punit::TestCase');
my $t= punit::TestCase->new();
# this test is of limited utility, we need a subclass.

assert_raises('VirtualBaseException', sub{ $t->run(); });
done_testing();


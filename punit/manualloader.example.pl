#!/usr/bin/env perl
use strict;
use warnings;
our $DEBUG = 0;

# edit the lines containing XXX
# (yes, you are tired; and you want this done already.)

use punit::SkelGen;

# this builder file is necessary as I didn't put my code on the $PERLINC
require 'your single large PL file';    # XXX

mkdir('./projectname');                 # XXX
mkdir('./projectname/t');               # XXX

my $t = punit::SkelGen->new( 'firstClass', 0, $DEBUG );    # XXX
my $ret = $t->generateTest();
print $ret if ($DEBUG);

$t->setTarget('SecondClass');                              # XXX
$ret = $t->generateTest();
print $ret if ($DEBUG);

# and so on, for each package


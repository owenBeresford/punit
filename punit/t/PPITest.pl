
	use strict;
	use Data::Dumper;
	use PPI;
	use File::Basename;

	my $doc;

	my $TESTFILE=dirname(__FILE__).'/Data/SampleClass.pm';

	$doc = PPI::Document->new($TESTFILE);
	print "Lookin' at ".$doc->find_first('PPI::Statement::Package')->namespace."\n";

	if (!( $doc->find_any('PPI::Token::Pod') || 
		 $doc->find_any('PPI::Token::Comment') )) {
		print "File contains no docs\n";
		exit();
	}

## due to thinking constraints only supporting full spec now
## see Element->snext_sibling for in func comments
	my $comments = $doc->find( 'PPI::Token::Comment') ;
	foreach my $c ( @{$comments}) {
		if( $c->content =~ m/\@assert/i  ) {
			print("Extracted generator line ", $c->content ,"\n");
		}
	}


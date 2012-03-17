use strict;
use lib 'lib';
use Data::Dumper;

use MarpaX::Parser::HTMLGen;
use MarpaX::CodeGen::HTMLGen;

my $infile = $ARGV[0];

open my $fh, '<', $infile or die "Can't open '$infile'";

my $codegen = MarpaX::CodeGen::HTMLGen->new;

my $parser = MarpaX::Parser::HTMLGen->new;
my $parse_tree = $parser->parse($fh);
print Dumper($parse_tree);

$codegen->generate_code($parse_tree);


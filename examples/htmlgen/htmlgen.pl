use strict;
use lib 'lib';
use Data::Dumper;

use MarpaX::Parser::HTMLGen;
use MarpaX::CodeGen::HTMLGen;
use MarpaX::CodeGen::Dumper;

my $infile = $ARGV[0];

open my $fh, '<', $infile or die "Can't open '$infile'";

#my $codegen = MarpaX::CodeGen::Dumper->new;
my $codegen = MarpaX::CodeGen::HTMLGen->new;

my $parser = MarpaX::Parser::HTMLGen->new;
my $parse_tree = $parser->parse($fh);
$codegen->generate_code(*STDOUT, $parse_tree);


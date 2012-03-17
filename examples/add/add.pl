
use MarpaX::Parser::Number;
use Data::Dumper;

my $p = MarpaX::Parser::Number->new();
my $tree = $p->parse(*STDIN);
print Dumper($tree);

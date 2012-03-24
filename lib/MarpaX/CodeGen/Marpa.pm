package MarpaX::CodeGen::Marpa;
use 5.14.2;
use strict;
use warnings;
use MarpaX::CodeGen;

$Data::Dumper::Deepcopy = 1;


sub new {
    my ($klass) = @_;
    return bless {}, $klass;
}

sub generate_code {
    my ($self, $parse_tree, $config) = @_;
    return MarpaX::CodeGen::generate_code($parse_tree, $config);
}

1;


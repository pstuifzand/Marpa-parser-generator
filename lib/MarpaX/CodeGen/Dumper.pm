package MarpaX::CodeGen::Dumper;
use 5.14.2;
use strict;
use warnings;
use Data::Dumper;

$Data::Dumper::Deepcopy = 1;


sub new {
    my ($klass) = @_;
    return bless {}, $klass;
}


sub generate_code {
    my ($self, $out_fh, $parse_tree) = @_;
    print {$out_fh} Dumper($parse_tree);
}

1;


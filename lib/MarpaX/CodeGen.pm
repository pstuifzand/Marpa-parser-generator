package MarpaX::CodeGen;
use 5.14.2;
use strict;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;

use parent 'Exporter';
our @EXPORT = qw/generate_code/;

sub generate_code {
    my ($parse_tree, $config) = @_;

    print <<'HEADER';
use strict;
use FindBin '$Bin';
use lib $Bin.'/lib';

use Marpa::XS;
use MarpaX::SimpleLexer;
HEADER

    if ($config->{dumper}) {
        print <<'HEADER';
use Data::Dumper;
HEADER
    }
    else {
        print <<'HEADER';
use MarpaX::CodeGen 'generate_code';
HEADER
    }

    print <<'HEADER';
my %tokens = (
HEADER

    for (@{ $parse_tree->{tokens} }) {
        if ($_->{regex}) {
            printf("       %-30s => qr/%s/,\n",$_->{lhs}, $_->{regex});
        }
        else {
            $_->{char} =~ s/^\$//;
            printf("       %-30s => '%s',\n", $_->{lhs}, $_->{char});
        }
    }

    #Name      => qr/(\w+)/,
    #DeclareOp => qr/::=/,
    #Plus      => qr/\+/,
    #Star      => qr/\*/,
    #CB        => qr/{{/,
    #CE        => qr/}}/,
    #Code      => qr/(.+)(?=}})/,

    print <<'HEADER';
);
HEADER

    print generate_actions($parse_tree, $config);
    print generate_parser_code($parse_tree, $config);

    print <<'OUT';
my $simple_lexer = MarpaX::SimpleLexer->new({
    create_grammar => \&create_grammar,
    tokens         => \%tokens,
});

open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0]";

my $parse_tree = $simple_lexer->parse($fh);
OUT

    if ($config->{dumper}) {
        print <<'OUT';
print Dumper($parse_tree);
OUT
    }
    else {
        print <<'OUT';
my $config = { namespace => 'My_Actions' };
generate_code($parse_tree, $config);
OUT
    }
}

sub generate_parser_code {
    my ($parse_tree, $config) = @_;

    my $namespace = $config->{namespace};

    my $out = <<"PRE";
sub create_grammar {
    my \$grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => '$namespace',
PRE

    $out .= generate_rules($parse_tree, $config);

    $out .= <<'POST';
            terminals => [keys %tokens],
        }
    );
    $grammar->precompute();
    return $grammar;
}
POST
}

sub generate_rules {
    my ($parse_tree) = @_;
    my $rules = $parse_tree->{rules};
    my $out = Dumper({rules=>$rules});
    $out =~ s/\$VAR\d+\s+=\s+{//;
    $out =~ s/};\n$/,/s;
    return $out;
}

sub generate_actions {
    my ($parse_tree, $config) = @_;
    my %actions;

    for (@{ $parse_tree->{rules} }) {
        my $c = @{ $actions{$_->{lhs}} || [] };
        my $name = $_->{lhs}.'_'.$c;
        $_->{action} = $name;
        push @{ $actions{$_->{lhs}} }, { name => $name, code => $_->{code} };
        delete $_->{code};
    }

    my $namespace = $config->{namespace};

    my $out = '';
    for my $rule_name (keys %actions) {
        for my $action (@{$actions{$rule_name}}) {
            $out .= "sub ${namespace}::$action->{name} {\n";
            $out .= "\t".$action->{code}."\n";
            $out .= "}\n\n";
        }
    }
    return $out;
}

1;

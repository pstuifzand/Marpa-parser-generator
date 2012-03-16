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
use Marpa::XS;
use MarpaX::CodeGen 'generate_code';

my %tokens = (
    Name      => qr/(\w+)/,
    DeclareOp => qr/::=/,
    Plus      => qr/\+/,
    Star      => qr/\*/,
    CB        => qr/{{/,
    CE        => qr/}}/,
    Code      => qr/(.+)(?=}})/,
);

sub parse_token_stream {
    my ($grammar, $fh) = @_;

    my $r= Marpa::XS::Recognizer->new( { grammar => $grammar } );

    LINE: while (<$fh>) {
        my $line = $_;
        chomp $line;

        while ($line) {
            $line =~ s/^\s+//;
            next LINE if $line =~ m/^\#/;

            for my $token_name (@{$r->terminals_expected}) {
                my $re = $tokens{$token_name};

                if ($line =~ s/^$re//) {
                    $r->read($token_name, $1 ? $1 : '');
                }
            }
        }
    }
    
    my $value_ref = $r->value;
    return $$value_ref;
}

HEADER

    print generate_actions($parse_tree, $config);
    print generate_parser_code($parse_tree, $config);

    print <<'OUT';
open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0]";

my $grammar = create_grammar();
my $parse_tree = parse_token_stream($grammar, $fh);

my $config = { namespace => 'My_Actions' };
generate_code($parse_tree, $config);

OUT

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
    my $out = Dumper($parse_tree);
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

package MarpaX::CodeGen::SimpleLex;
use 5.14.2;
use strict;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;

use Carp;

sub new {
    my ($klass, $config) = @_;
    my $self = bless { config => $config }, $klass;

    if (!defined $config->{package}) {
        croak "Variable 'package' not specified";
    }

    return $self;
}

sub find_inline_tokens {
    my ($parse_tree) = @_;
    my $c = 0;

    my %token_to_name;

    for my $rule (@{$parse_tree->{rules}}) {
        my $i = 0;
        for my $rhs (@{ $rule->{rhs} }) {
            if (ref($rhs) eq 'HASH') {
                if ($rhs->{token}) {
                    my $name;
                    if ($token_to_name{$rhs->{token}}) {
                        $name = $token_to_name{$rhs->{token}};
                    }
                    else {
                        $name = 'TOK_'.$c;
                        $c++;
                        $token_to_name{$rhs->{token}} = $name;
                        push @{$parse_tree->{tokens}}, { lhs => $name, char => $rhs->{token} };
                    }
                    $rule->{rhs}[$i] = $name;
                }
            }
        }
        continue { $i++; }
    }
    return;
}

sub generate_code {
    my ($self, $parse_tree) = @_;

    my $package = $self->{config}->{package};

    find_inline_tokens($parse_tree);

    print "package $package;\n";

    print <<'HEADER';
use strict;

use Marpa::XS;
use MarpaX::Simple::Lexer;
HEADER

    generate_tokens($parse_tree->{tokens});

    print generate_actions($parse_tree, $self->{config});
    print generate_parser_code($parse_tree, $self->{config});

    print <<'OUT';
sub new {
    my ($klass) = @_;
    my $self = bless {}, $klass;
    return $self;
}

sub parse {
    my ($self, $fh) = @_;
    my $grammar = create_grammar();
    my $recognizer = Marpa::XS::Recognizer->new({ grammar => $grammar });
    my $simple_lexer = MarpaX::Simple::Lexer->new(
        recognizer     => $recognizer,
#        input_filter   => sub { ${$_[0]} =~ s/[\r\n]+//g },
        tokens         => \%tokens,
    );
    $simple_lexer->recognize($fh);
    my $parse_tree = ${$recognizer->value};
    return $parse_tree;
}

1;
OUT
}

sub generate_tokens {
    my ($tokens) = @_;

    print <<'HEADER';
my %tokens = (
HEADER

    for (@{ $tokens }) {
        if ($_->{regex}) {
            printf("       %-30s => qr/%s/,\n",$_->{lhs}, $_->{regex});
        }
        else {
            $_->{char} =~ s/^\$//;
            if ($_->{char} eq "'") {
                $_->{char} = "\\'";
            }
            printf("       %-30s => '%s',\n", $_->{lhs}, $_->{char});
        }
    }

    print <<'HEADER';
);
HEADER
}

sub generate_parser_code {
    my ($parse_tree, $config) = @_;

    my $namespace = $config->{package} . '::Actions';

    my $out = <<"PRE";
sub create_grammar {
    my \$grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => '$namespace',
PRE

    $out .= generate_rules($parse_tree, $config);

    $out .= <<'POST';
            lhs_terminals => 0,
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
    for (@$rules) {
        if (@{$_->{rhs}} == 1 && $_->{rhs}[0] eq 'Null'){
            $_->{rhs} = [];
        }
    }
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

    my $namespace = $config->{package} . '::Actions';

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


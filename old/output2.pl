use v5.10;
use strict;
use Marpa::XS;
use Data::Dumper;
use My_Actions;

$Data::Dumper::Deepcopy = 1;

my %tokens = (
    Name      => qr/(\w+)/,
    DeclareOp => qr/::=/,
    Plus      => qr/\+/,
    Star      => qr/\*/,
    CB        => qr/{{/,
    CE        => qr/}}/,
    Code      => qr/(.+)(?=}})/,
);

sub My_Actions::Lhs_0 {
	shift; return [ lhs => $_[0] ]           
}
sub My_Actions::Names_0 {
	shift; return [ @_ ];                    
}
sub My_Actions::Rhs_0 {
	shift; return [ rhs => $_[0] ]           
}
sub My_Actions::Rhs_1 {
	shift; return [ rhs => $_[0], min => 1 ] 
}
sub My_Actions::Rhs_2 {
	shift; return [ rhs => $_[0], min => 0 ] 
}
sub My_Actions::Parser_0 {
	shift; return { 'rules' => \@_ }         
}
sub My_Actions::Rule_0 {
	shift; return { @{$_[0]}, @{$_[2]} }     
}
sub My_Actions::Rule_1 {
	shift; return { @{$_[0]}, @{$_[2]}, code => $_[4] }     
}
sub create_grammar {
    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => 'My_Actions',

          'rules' => [
                       {
                         'min' => 1,
                         'rhs' => [
                                    'Rule'
                                  ],
                         'lhs' => 'Parser',
                         'action' => 'Parser_0'
                       },
                       {
                         'rhs' => [
                                    'Lhs',
                                    'DeclareOp',
                                    'Rhs'
                                  ],
                         'lhs' => 'Rule',
                         'action' => 'Rule_0'
                       },
                       {
                         'rhs' => [
                                    'Lhs',
                                    'DeclareOp',
                                    'Rhs',
                                    'CB',
                                    'Code',
                                    'CE'
                                  ],
                         'lhs' => 'Rule',
                         'action' => 'Rule_1'
                       },
                       {
                         'rhs' => [
                                    'Name'
                                  ],
                         'lhs' => 'Lhs',
                         'action' => 'Lhs_0'
                       },
                       {
                         'rhs' => [
                                    'Names'
                                  ],
                         'lhs' => 'Rhs',
                         'action' => 'Rhs_0'
                       },
                       {
                         'rhs' => [
                                    'Names',
                                    'Plus'
                                  ],
                         'lhs' => 'Rhs',
                         'action' => 'Rhs_1'
                       },
                       {
                         'rhs' => [
                                    'Names',
                                    'Star'
                                  ],
                         'lhs' => 'Rhs',
                         'action' => 'Rhs_2'
                       },
                       {
                         'min' => 1,
                         'rhs' => [
                                    'Name'
                                  ],
                         'lhs' => 'Names',
                         'action' => 'Names_0'
                       }
                     ],
                     terminals => [keys %tokens],
        }    );
    $grammar->precompute();
    return $grammar;
}

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
    $out =~ s/};\n$/}/s;
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

    for my $rule_name (keys %actions) {
        for my $action (@{$actions{$rule_name}}) {
            say "sub ${namespace}::$action->{name} {";
            say "\t".$action->{code};
            say "}";
        }
    }
}

open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0]";

my $grammar = create_grammar();
my $parse_tree = parse_token_stream($grammar, $fh);

my $config = { namespace => 'My_Actions' };
generate_actions($parse_tree, $config);
print generate_parser_code($parse_tree, $config);


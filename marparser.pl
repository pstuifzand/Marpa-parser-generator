# Generates a Marpa parser for parsing Marpa
# Copyright (C) 2011  Peter Stuifzand
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
 
sub create_grammar {
    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => 'My_Actions',
            rules   => [
                { lhs => 'Parser', rhs => [qw/Rule/], min => 1 },
                { lhs => 'Rule', rhs => [qw/Lhs DeclareOp Rhs/], action => 'Rule' },
                { lhs => 'Rule', rhs => [qw/Lhs DeclareOp Rhs CB Code CE/], action => 'RuleWithCode' },
                { lhs => 'Lhs', rhs => [qw/Name/] },
                { lhs => 'Rhs', rhs => [qw/Names/] },
                { lhs => 'Rhs', rhs => [qw/Names Plus/], action => 'Plus' },
                { lhs => 'Rhs', rhs => [qw/Names Star/], action => 'Star' },
                { lhs => 'Names', rhs => [qw/Name/], min => 1 },
            ],
            terminals => [keys %tokens],
        }
    );
    
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
            #say $line;

            for my $token_name (@{$r->terminals_expected}) {
                #say $token_name;
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


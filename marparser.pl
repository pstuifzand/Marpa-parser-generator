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
use MarpaX::CodeGen 'generate_code';
use MarpaX::SimpleLexer;
use Marpa::XS;
use Data::Dumper;
use My_Actions;

$Data::Dumper::Deepcopy = 1;

my %tokens = (
    Name      => qr/(\w+)/,
    DeclareOp => qr/::=/,
    Plus      => '+',
    Star      => '*',
    CB        => qr/{{/,
    CE        => qr/}}/,
    Code      => qr/(?<!{{)\s*(.+)\s*(?=}})/,
    EQ        => '=',
    Char      => qr/\$(.)/,
    SLASH     => '/',
    RX        => qr/(?<!\/)(.+)(?=(?<!\/))/,
);
 
sub create_grammar {
    my ($terminals) = @_;

    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => 'My_Actions',
            rules   => [
                { lhs => 'Parser',    rhs => [qw/Decl/], min => 1 },
                { lhs => 'Decl',      rhs  => [qw/Rule/], action => 'DeclRule' },
                { lhs => 'Decl',      rhs  => [qw/TokenRule/], action => 'DeclToken' },
                { lhs => 'TokenRule', rhs => [qw/Lhs EQ SLASH RX SLASH/], action => 'TokenRule_0' },
                { lhs => 'TokenRule', rhs => [qw/Lhs EQ Char/], action => 'TokenRule_1' },
                { lhs => 'Rule',      rhs => [qw/Lhs DeclareOp Rhs/], action => 'Rule' },
                { lhs => 'Rule',      rhs => [qw/Lhs DeclareOp Rhs CB Code CE/], action => 'RuleWithCode' },
                { lhs => 'Lhs',       rhs => [qw/Name/] },
                { lhs => 'Rhs',       rhs => [qw/Names/] },
                { lhs => 'Rhs',       rhs => [qw/Names Plus/], action => 'Plus' },
                { lhs => 'Rhs',       rhs => [qw/Names Star/], action => 'Star' },
                { lhs => 'Names',     rhs => [qw/Name/], min => 1 },
            ],
            terminals => $terminals,
        }
    );
    
    $grammar->precompute();
    return $grammar;
}

my $simple_lexer = MarpaX::SimpleLexer->new({
    create_grammar => \&create_grammar,
    tokens         => \%tokens,
});

open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0]";

my $parse_tree = $simple_lexer->parse($fh);
#print Dumper($parse_tree);

my $config = { namespace => 'My_Actions' };
generate_code($parse_tree,$config);


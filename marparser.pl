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
 
sub create_grammar {
    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => 'My_Actions',
            rules   => [
                { lhs => 'Parser', rhs => [qw/Rule/], min => 1 },
                { lhs => 'Rule', rhs => [qw/Lhs DeclareOp Rhs/] },
                { lhs => 'Lhs', rhs => [qw/Name/] },
                { lhs => 'Rhs', rhs => [qw/Names/] },
                { lhs => 'Rhs', rhs => [qw/Names Plus/] },
                { lhs => 'Rhs', rhs => [qw/Names Star/] },
                { lhs => 'Names', rhs => [qw/Name/], min => 1 },
            ],
        }
    );
    
    $grammar->precompute();
    return $grammar;
}

sub parse_token_stream {
    my ($grammar, $fh) = @_;
    my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );

    LINE: while (<$fh>) {
        my $line = $_;
        chomp $line;

        while ($line) {
            $line =~ s/^\s+//;

            next LINE if $line =~ m/^\#/;

            if ($line =~ s/^(\w+)//) {
                $recce->read('Name', $1);
            }
            elsif ($line =~ s/^::=//) {
                $recce->read('DeclareOp');
            }
            elsif ($line =~ s/^\+//) {
                $recce->read('Plus', 1);
            }
            elsif ($line =~ s/^\*//) {
                $recce->read('Star', 0);
            }
        }
    }
    
    my $value_ref = $recce->value;
    return $$value_ref;
}

open my $fh, '<', $ARGV[0] or die "Can't open $ARGV[0]";

my $grammar = create_grammar();
my $value_ref = parse_token_stream($grammar, $fh);

print <<'PRE';
sub create_grammar {
    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Parser',
            actions => 'My_Actions',
PRE
my $out = Dumper($value_ref);
$out =~ s/\$VAR\d+\s+=\s+{//;
$out =~ s/};\n$/}/s;
print $out;

print <<'POST';
    );
    
    $grammar->precompute();
    return $grammar;
}
POST


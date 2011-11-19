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
use Marpa::XS;
use Data::Dumper;
 
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
 
my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );
 
open my $fh, '<', 'marpa.mp' or die "Can't open marpa.mp";

while (<$fh>) {
    my $line = $_;
    chomp $line;

    while ($line) {
        $line =~ s/^\s+//;
        next if $line =~ m/^#/;
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

sub My_Actions::Parser {shift;return {'rules' => \@_ }; }
sub My_Actions::Rule {shift;return { @{$_[0]}, @{$_[2]} }; }
sub My_Actions::Lhs {shift;return [lhs => $_[0]];}
sub My_Actions::Rhs {shift;return [rhs => $_[0]];}
sub My_Actions::Rhs {
    shift;
    if (@_ == 1) {
        return [rhs => $_[0]];
    }
    elsif (@_ == 2) {
        return [rhs => $_[0], min => $_[1]];
    }
}
sub My_Actions::Names {shift;return [@_];}
 
my $value_ref = $recce->value;
print <<'PRE';
use v5.10;
use Marpa::XS;
use Data::Dumper;
 
my $grammar = Marpa::XS::Grammar->new(
    {   start   => 'Parser',
        actions => 'My_Actions',
PRE
my $out = Dumper($$value_ref);
$out =~ s/\$VAR\d+\s+=\s+{//;
$out =~ s/};\n$/}/s;
print $out;

print <<'POST';
);
 
$grammar->precompute();
 
my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );
POST


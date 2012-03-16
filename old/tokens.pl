use v5.10;
use Marpa::XS;
use Data::Dumper;
 
my $grammar = Marpa::XS::Grammar->new(
    {   start   => 'Parser',
        actions => 'My_Actions',
        rules   => [
            { lhs => 'Parser', rhs => [ 'NumberLine' ], min => 1, action => 'Parser' },
            { lhs => 'NumberLine', rhs => [ 'NumberList', "\n" ], action => 'NumberLine' },
            { lhs => 'NumberList', rhs => ['Number'] },
            { lhs => 'NumberList', rhs => ['Number', 'WS', 'NumberList'] },
            { lhs => 'Number', rhs => ['Digit'], min => 1, action => 'Number' },
            { lhs => 'Digit', rhs => ['0'] },
            { lhs => 'Digit', rhs => ['1'] },
            { lhs => 'Digit', rhs => ['2'] },
            { lhs => 'Digit', rhs => ['3'] },
            { lhs => 'Digit', rhs => ['4'] },
            { lhs => 'Digit', rhs => ['5'] },
            { lhs => 'Digit', rhs => ['6'] },
            { lhs => 'Digit', rhs => ['7'] },
            { lhs => 'Digit', rhs => ['8'] },
            { lhs => 'Digit', rhs => ['9'] },
            { lhs => 'WS', rhs => [ ' ' ], min => 1 },
        ],
    }
);
use List::Util 'sum';
 
sub My_Actions::Parser { shift;return [ map { if (ref) { @$_ } else { $_ } } @_ ];  }
sub My_Actions::NumberLine { shift; pop; return [ map { if (ref) { @$_ } else { $_ } } @_ ]; }
sub My_Actions::NumberList { shift; return [ $_[0] ] if (@_ == 1); return [ $_[0], @{$_[2]} ] if @_ == 3; }
sub My_Actions::Number { shift; return [ 'Number', (join '', @_) ] }
sub My_Actions::Digit { shift; return $_[0]; }
sub My_Actions::WS { shift; return; }

$grammar->precompute();
 
my $re = Marpa::XS::Recognizer->new( { grammar => $grammar } );

while (<>) {
    my @tokens = split //;
    for (@tokens) {
        $re->read($_, $_);
    }
}

my $value_ref = $re->value;
say Dumper($$value_ref);


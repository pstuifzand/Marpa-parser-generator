package Tokenizer;
use v5.10;
use Marpa::XS;
use Data::Dumper;
use Tokenizer::Actions;
 
sub parse_token_stream {
    my ($fh) = @_;

    my $grammar = Marpa::XS::Grammar->new(
        {   start   => 'Tokenizer',
            actions => 'Tokenizer::Actions',

            rules   => [
                { lhs => 'Tokenizer', rhs => [qw/Rule/], min => 1, action => 'rules'},
                { lhs => 'Rule', rhs => [qw/Lhs DeclareOp Rhs/], action => 'rule' },
                { lhs => 'Lhs', rhs => [qw/Name/], action => 'name' },
                { lhs => 'Rhs', rhs => [qw/Regex/], action => 'regex' },
            ],
        }
    );
    
    $grammar->precompute();
    
    my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );
    
    LINE: while (<>) {
        my $line = $_;
        chomp $line;

        while ($line) {
            $line =~ s/^\s+//;
            next LINE if $line =~ m/^\#/;

            if ($line =~ s{^R:(.*)$}{}) {
                $recce->read('Regex', $1);
            }
            elsif ($line =~ s/^(\w+)//) {
                $recce->read('Name', $1);
            }
            elsif ($line =~ s/^::=//) {
                $recce->read('DeclareOp');
            }
            else {
                die "Unknown rest of line: $line";
            }
        }
    }
    
    my $value_ref = $recce->value;
    return $$value_ref;
}

1;


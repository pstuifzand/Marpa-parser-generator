use 5.14.2;
use Tokenizer;
use Data::Dumper;

my $val = Tokenizer::parse_token_stream(\*STDIN);

print <<'HEADER';
sub parse_token_stream {
    my ($grammar, $fh) = @_;
    my $recce = Marpa::XS::Recognizer->new( { grammar => $grammar } );
    
    LINE: while (<$fh>) {
        my $line = $_;
        chomp $line;

        while ($line) {
            $line =~ s/^\s+//;
            next LINE if $line =~ m/^\#/;
HEADER

for my $rule (@$val) {
    if ($rule->{regex} =~ m/\(|\)/) {
        print <<"LINE";
            if (\$line =~ s{^$rule->{regex}}{}) {
                \$recce->read("$rule->{name}", \$1);
                next;
            }
LINE
    }
    else {
        print <<"LINE";
            if (\$line =~ s{^$rule->{regex}}{}) {
                \$recce->read("$rule->{name}");
                next;
            }
LINE
    }
}

print <<'FOOTER';
        }
    }
    my $value_ref = $recce->value;
    return $$value_ref;
}
FOOTER


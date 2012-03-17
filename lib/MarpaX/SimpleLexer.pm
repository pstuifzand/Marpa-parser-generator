package MarpaX::SimpleLexer;
use strict;
use 5.14.2;
use Data::Dumper;

sub new {
    my ($klass, $options) = @_;

    my $self = bless {
        create_grammar => $options->{create_grammar},
        tokens         => $options->{tokens},
    }, $klass;

    $self->_create_grammar();
    return $self;
}

sub _create_grammar {
    my ($self) = @_;
    $self->{grammar} = $self->{create_grammar}->([keys %{$self->{tokens}}]);
    return;
}

sub parse {
    my ($self, $fh) = @_;
    return $self->_parse_token_stream($fh);
}

sub _parse_token_stream {
    my ($self, $fh) = @_;

    my $r = Marpa::XS::Recognizer->new( { grammar => $self->{grammar} } );

    my $c = 0;
    LINE: while (<$fh>) {
        my $line = $_;
        chomp $line;

        #say STDERR "=====================";
        PART: while (length $line > 0) {
            #$line =~ s/^\s+//;
            #say STDERR "Line:    $line";
            next LINE if $line =~ m/^\#/;

            for my $token_name (@{$r->terminals_expected}) {

                #say STDERR "Token:   $token_name";
                my $re = $self->{tokens}{$token_name};

                if (ref($re) eq 'Regexp') {

                    #say STDERR 're';

                    if ($line =~ s/^$re//s) {
#                        #say "[$1]";
                        if ($r->read($token_name, $1)) {
                            next PART;
                        }
                    }
                }
                else {
                    ##say STDERR "RE: [$re][$line]";
                    #say STDERR "ORD: [".ord($re)."][".ord($line)."]";

                    if (ord($re) == ord($line)) {
                        my $read = $r->read($token_name, $re);
                        $line = substr $line, 1;
                        next PART;
                    }
                }
            }
            $line =~ s/^\s+//;
            if (length $line> 0) {
                # Didn't know what to do...
                #warn 'hmm ' . $line;
#                die "No expected terminal found here";
            }
        }
    }
    
    my $value_ref = $r->value;
    return $$value_ref;
}

1;


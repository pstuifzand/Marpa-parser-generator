package Marp::App;
use 5.10.0;

use strict;
use warnings;

use MarpaX::Parser::Marpa;

sub new {
    my ($klass) = @_;
    my $self = bless {}, $klass;
    return $self;
}

sub parse_args {
    my ($self, @args) = @_;
    $self->{infile} = $args[0];
    $self->{codegen}  = $args[1];
    $self->{package}  = $args[2];
    return;
}

sub run {
    my ($self) = @_;

    my $infile = $self->{infile};

    open my $fh, '<', $infile or die "Can't open '$infile'";

    my $codegen_class = $self->{codegen} // 'MarpaX::CodeGen::Dumper';
    eval "require $codegen_class";
    my $codegen = $codegen_class->new({package => $self->{package}});

    my $parser = MarpaX::Parser::Marpa->new();
    my $parse_tree = $parser->parse($fh);

    $codegen->generate_code($parse_tree);

    return;
}

1;

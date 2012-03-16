package Tokenizer::Actions;
use Data::Dumper;

sub rules {
    my (undef, @rules) = @_;
    return \@rules;
}

sub rule {
    return { name => $_[1], regex => $_[3] };
}

sub name {
    return $_[1];
}

sub regex {
    return $_[1];
}

1;

package MarpaX::CodeGen::HTMLGen;
use strict;
use warnings;
use 5.14.2;

sub new {
    my ($klass) = @_;
    return bless {
        strings     => {},
        str_count   => 0,
        lines       => [],
        label_count => 0,
    }, $klass;
}

sub add_string {
    my ($self, $string) = @_;
    my $l = sprintf('STR_%04d',$self->{str_count});
    $self->{str_count}++;
    $self->{strings}{$l} = $string;
    return $l;
}

sub generate_code {
    my ($self, $tree) = @_;

    $self->_generate_code($tree);
    $self->add_line("End");

    for my $key (sort keys %{$self->{strings}}) {
        print "\t".'.STR ' . $key . " " . $self->{strings}{$key} . "\n";
    }
    print "\n";

    for my $line (@{$self->{lines}}) {
        if ($line =~ m/:$/) {
            print $line . "\n";
        }
        else {
            print "\t" . $line . "\n";
        }
    }
}

sub add_line {
    my ($self, $line) = @_;
    push @{$self->{lines}}, $line;
    return;
}

#=====================================
sub emit_out {
    my ($self, @str) = @_;

    for (@str) {
        #s/"/\\"/g;

        if (m/^@/) {
            $self->add_line(qq{Emit $_});
        }
        else {
            my $l = $self->add_string($_);
            $self->add_line(qq{Emit $l});
        }
    }
}

sub gen_lbl {
    my ($self) = @_;
    my $lbl = 'L'.$self->{label_count};
    $self->{label_count}++;
    return $lbl;
}

sub emit_label {
    my ($self, $lbl) = @_;
    $self->add_line("$lbl:");
    return;
}

sub emit_if_exists {
    my ($self, $name, $lbl) = @_;
    $self->add_line('Exists '. $name);
    $self->add_line('JF '. $lbl);
}

sub _generate_code {
    my ($self, $tree) = @_;

    if (ref($tree) eq 'ARRAY') {
        for (@$tree) {
            $self->_generate_code($_);
        }
    }
    elsif (ref($tree) eq 'HASH') {
        if (exists $tree->{_if}) {
            my $lbl = $self->gen_lbl();
            $self->emit_if_exists($_->{_if}, $lbl);
            $self->_generate_code($_->{_block});
            $self->emit_label($lbl);
        }
        elsif (exists $tree->{_tag}) {
            if (!exists $tree->{_attrs}) {
                $self->emit_out('<' . $tree->{_tag} . '>');
            }
            else {
                $self->emit_out('<' . $tree->{_tag});
                for my $attr (@{$tree->{_attrs}}) {
                    $self->emit_out(' '.$attr->{_id}.'="');
                    if (exists $attr->{_string}) {
                        $self->emit_out($attr->{_string}{_str});
                    }
                    else {
                        $self->emit_out($attr->{_atid});
                    }
                    $self->emit_out('"');
                }
                $self->emit_out('>');
            }

            if (exists $tree->{_block}) {
                $self->_generate_code($tree->{_block});
                $self->emit_out('</' . $tree->{_tag} . '>');
            }
        }
        elsif (exists $tree->{_str}) {
            $self->emit_out($tree->{_str});
        }
    }
    else {
        $self->emit_out($tree);
    }
}

1;

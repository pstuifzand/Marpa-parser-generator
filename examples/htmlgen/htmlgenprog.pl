#!/usr/bin/perl -w
use 5.14.1;
use Data::Dumper;
use Regexp::Common;

sub load_program {
    my ($fh) = @_;

    my @program;
    my %labels;
    my %strings;

    while (<$fh>) {
        chomp;

        s/^\s+//;

        if (m/^\.STR\t(\w+)\t($RE{quoted})$/) {
            my $k = $1;
            my $v = $2;
            $v =~ s/^"//;
            $v =~ s/"$//;
            $v =~ s/\\"/"/g;
            $v =~ s/\\n/\n/g;
            $strings{$k} = $v;
        }
        elsif (m/^Emit\s+(\w+)/) {
            my $k = $1;
            push @program, [ 'Emit', $strings{$k} ];
        }
        elsif (m/^Emit\s+\@(\w+)$/) {
            my $key = $1;
            push @program, [ 'Emit_Field', $key ];
        }
        elsif (m/^Exists\s+\@(\w+)$/) {
            my $key = $1;
            push @program, [ 'Exists', $key ];
        }
        elsif (m/^End$/) {
            push @program, [ 'End' ];
        }
        elsif (m/^JF\s+(\w+)$/) {
            push @program, [ 'JF', $1 ];
        }
        elsif (m/^JT\s+(\w+)$/) {
            push @program, [ 'JE', $1 ];
        }
        elsif (m/^(\w+):/) {
            $labels{$1} = scalar @program;
        }
    }
    return (\%labels, \@program);
}

sub create_machine {
    my $filename = shift;

    my %opcodes = (
        Emit       => sub { print $_[1]; return $_[0]->{ip}+1 },
        Emit_Field => sub { print $_[0]->{data}{$_[1]}||''; return $_[0]->{ip}+1 },
        Exists     => sub { $_[0]->{jmp_flag} = exists $_[0]->{data}{$_[1]}; return $_[0]->{ip}+1 },
        JF         => sub { return !$_[0]->{jmp_flag} ? $_[0]->{labels}{$_[1]} : $_[0]->{ip}+1; },
        JT         => sub { return $_[0]->{jmp_flag}  ? $_[0]->{labels}{$_[1]} : $_[0]->{ip}+1; },
        End        => sub { return -1; },
    );

    open my $fh, '<', $filename or die "Can't open $filename";
    my ($labels, $program) = load_program($fh);

    return sub {
        my ($data) = @_;

        my $machine = {
            jmp_flag => 0,
            ip       => 0,
            data     => $data,
            labels   => $labels,
            program  => $program,
        };

        while ($machine->{ip} >= 0) {
            my $instr = $program->[$machine->{ip}];
            $machine->{ip} = $opcodes{ $instr->[0] }->($machine, $instr->[1]);
        }
    }
}

*output_html = create_machine($ARGV[0]);

print <<"HEADER";
<style>
label {
    font-weight:bold;
}
span.description {
    color:#555;
    font-size:9pt;
}
input {
    display:block;
}
</style>
HEADER

my @description = (
    {
        id          => 'sku',
        name        => 'sku',
        description => 'Unieke code',
        title       => 'SKU',
    },
    {
        id          => 'barcode',
        name        => 'barcode',
        description => 'Niet verplicht',
        title       => 'Streepjescode',
    },
    {
        id          => 'name',
        name        => 'name',
        title       => 'Naam',
        description => 'Naam van uw product',
    },
    {
        id          => 'price',
        name        => 'price',
        title       => 'Prijs',
        description => 'In euro cent incl. btw',
    },
);

for (@description) {
    output_html($_);
}


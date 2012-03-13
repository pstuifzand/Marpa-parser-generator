package My_Actions;

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

1;

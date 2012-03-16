package My_Actions;

sub My_Actions::Parser {shift;return {'rules' => \@_ }; }
sub My_Actions::Rule {shift;return { @{$_[0]}, @{$_[2]} }; }
sub My_Actions::RuleWithCode {shift;return { @{$_[0]}, @{$_[2]}, code => $_[4] }; }
sub My_Actions::Lhs {shift;return [lhs => $_[0]];}
sub My_Actions::Rhs {shift;return [rhs => $_[0]];}
sub My_Actions::Star {
    shift;
    return [rhs => $_[0], min => 0];
}
sub My_Actions::Plus {
    shift;
    return [rhs => $_[0], min => 1];
}
sub My_Actions::Names {shift;return [@_];}

1;


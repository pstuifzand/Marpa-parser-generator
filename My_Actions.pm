package My_Actions;

sub My_Actions::Parser {my $ast = shift;return $ast;} 

sub My_Actions::DeclRule {my $ast = shift; push @{$ast->{rules}}, $_[0]; }
sub My_Actions::DeclToken {my $ast = shift; push @{$ast->{tokens}}, $_[0]; }

sub My_Actions::TokenRule_0 {shift;return { @{$_[0]}, regex => qr/$_[3]/ }; }
sub My_Actions::TokenRule_1 {shift;return { @{$_[0]}, char  => $_[2] }; }

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


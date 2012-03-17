Name      = /(\w+)/
DeclareOp = /::=/
Plus      = $+
Star      = $*
CB        = /{{/
CE        = /}}/
Code      = /(?<!{{)\s*(.+)\s*(?=}})/
SLASH     = $/
EQ        = $=
RX        = /(?<!\/)(.+)(?=(?<!\/))/
Char      = /\$(.)/
Space     = /[ \r\n]+/
Comment   = /\#.*$/

Parser    ::= Decl+                             {{ return $_[0]; }}
Decl      ::= Rule WS                           {{ push @{$_[0]->{rules}}, $_[1] }}
Decl      ::= TokenRule WS                      {{ push @{$_[0]->{tokens}}, $_[1] }}
TokenRule ::= Lhs WS EQ WS SLASH RX SLASH       {{ shift; return { @{$_[0]}, regex => qr/$_[5]/ } }}
TokenRule ::= Lhs WS EQ WS Char                 {{ shift; return { @{$_[0]}, 'char' => $_[4] } }}
Rule      ::= Lhs WS DeclareOp WS Rhs                {{ shift; return { @{$_[0]}, @{$_[4]} }     }}
Rule      ::= Lhs WS DeclareOp WS Rhs WS CB Code CE  {{ shift; return { @{$_[0]}, @{$_[4]}, code => $_[7] }     }}
Lhs       ::= Name                              {{ shift; return [ lhs => $_[0] ]           }}
Rhs       ::= Names                             {{ shift; return [ rhs => $_[0] ]           }}
Rhs       ::= Names Star                        {{ shift; return [ rhs => $_[0], min => 0 ] }}
Rhs       ::= Names Plus                        {{ shift; return [ rhs => $_[0], min => 1 ] }}
Names     ::= NamePart+                         {{ shift; return [ @_ ];                    }}
NamePart  ::= WS Name                           {{ shift; return $_[1]; }}
NamePart  ::= WS Char                           {{ shift; return { token => $_[1] }; }}
WS        ::= Null
WS        ::= Space

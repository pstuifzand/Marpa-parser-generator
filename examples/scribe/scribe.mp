AT    = $@
LP    = $(
RP    = $)
LB    = $[
RB    = $]
LS    = ${
RS    = $}
Word  = /([A-Za-z]+)/
Begin = /Begin/
End   = /End/
Char  = /(.)/

Parser     ::= Tree                   {{ shift; return $_[0]; }}
Tree       ::= Expression+            {{ shift; return \@_; }}
Expression ::= BeginExpr Tree EndExpr {{ shift; return { tree => 1, word => $_[0]->{word}, _content => $_[1] }; }}

BeginExpr ::= AT Begin LP Word RP     {{ return { word => $_[4] }; }}
BeginExpr ::= AT Begin LB Word RB     {{ return { word => $_[4] }; }}
BeginExpr ::= AT Begin LS Word RS     {{ return { word => $_[4] }; }}

EndExpr ::= AT End LP Word RP         {{ return { word => $_[4], end => 1 }; }}
EndExpr ::= AT End LB Word RB         {{ return { word => $_[4], end => 1 }; }}
EndExpr ::= AT End LS Word RS         {{ return { word => $_[4], end => 1 }; }}

Expression ::= AT Word LP Text RP    {{ return { expression => 1, word => $_[2], _content => $_[4] } }}
Expression ::= AT Word LB Text RB    {{ return { expression => 1, word => $_[2], _content => $_[4] } }}
Expression ::= AT Word LS Text RS    {{ return { expression => 1, word => $_[2], _content => $_[4] } }}

Expression ::= Text                   {{ shift; return { text => $_[0] }; }}
Text       ::= Char+                  {{ shift; return join '', @_;  }}


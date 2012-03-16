KW_Ent  = /entity/
ID      = /(\w+)/
String  = /"([^"]+)"/

Parser     ::= EntityDecl+         {{ shift; return \@_; }}
EntityDecl ::= KW_Ent ID String    {{ return { id => $_[2], string => $_[3] } }}


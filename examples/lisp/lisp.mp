
String = /"([^"]+)"/
Number = /(\d+)/
Symbol = /([a-z]+)/

Parser      ::= Expression+    {{ shift; return \@_; }}
Expression  ::= $( List $)     {{ shift; return $_[1]; }}
List        ::= Expression+    {{ shift; return \@_; }}
Expression  ::= String         {{ shift; return { string => $_[0] }; }}
Expression  ::= Number         {{ shift; return { number => $_[0] }; }}
Expression  ::= Symbol         {{ shift; return { symbol => $_[0] }; }}


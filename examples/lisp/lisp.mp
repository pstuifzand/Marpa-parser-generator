String = /"([^"]+)"/
Number = /(\d+)/
Symbol = /([a-z]+)/
Space  = /[ \r\n\t]+/

Parser      ::= Expression+                                     {{ shift; return \@_;                   }}
Expression  ::= WS $( WS Parser WS $) WS                        {{ shift; return $_[3];                 }}
Expression  ::= WS $( WS Expression WS $. WS Expression WS $) WS {{ shift; return [ $_[3], $_[7] ];                 }}
Expression  ::= WS $( WS $) WS                                  {{ shift; return 'nil';                 }}
Expression  ::= WS String WS                                    {{ shift; return { string => $_[1] };   }}
Expression  ::= WS Number WS                                    {{ shift; return { number => $_[1] };   }}
Expression  ::= WS Symbol WS                                    {{ shift; return $_[1];                 }}
Expression  ::= WS $' Expression WS                             {{ shift; return [ 'quote', $_[2] ];    }}
WS          ::= Space
WS          ::= Null


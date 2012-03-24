String = /"([^"]*)"/
Number = /(\d+)/
Symbol = /([a-z]+)/
Space  = /[ \r\n\t]+/

Parser      ::= Expression+                                       {{ my $lsp = shift; return $lsp if $lsp->{error}; return \@_; }}
Expression  ::= WS $( WS Parser WS $) WS                          {{ shift; return $_[3];                 }}
Expression  ::= WS $( WS Parser WS                                {{ my $lisp = shift; $lisp->{error} = "Expression is not closed"; return;}}
Expression  ::= WS $( WS Expression WS $. WS Expression WS $) WS  {{ shift; return [ $_[3], $_[7] ];      }}
Expression  ::= WS $( WS $) WS                                    {{ shift; return [];                    }}
Expression  ::= WS String WS                                      {{ shift; return { type => 'string', val => $_[1] }; }}
Expression  ::= WS Number WS                                      {{ shift; return { type => 'number', val => $_[1] }; }}
Expression  ::= WS Symbol WS                                      {{ shift; return { type => 'symbol', val => $_[1] }; }}
Expression  ::= WS $' Expression WS                               {{ shift; return [ 'quote', $_[2] ];    }}
WS          ::= Space
WS          ::= Null


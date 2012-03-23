WS     = /[ \t\n\r]+/
Id     = /([a-z_\-]+)/
Tag    = /(\w+)/
Char   = /([^"])/

Parser     ::= Tree+                                {{ shift; return \@_; }}

Tree       ::= Space Tag Block                      {{ shift; return { _tag => $_[1], _block => $_[2] } }}
Tree       ::= Space Tag Attrs                      {{ shift; return { _tag => $_[1], _attrs => $_[2] } }}
Tree       ::= Space Tag Attrs Block                {{ shift; return { _tag => $_[1], _attrs => $_[2], _block => $_[3] } }}
Tree       ::= Space AtId                           {{ shift; return $_[1]; }}
Tree       ::= Space String Space                   {{ shift; return $_[1]; }}
Tree       ::= Space $? AtId Space Block            {{ shift; return { _if => $_[2], _exists => 1, _block => $_[4] } }}
Tree       ::= Space $? $! AtId Space Block         {{ shift; return { _if => $_[3], _exists => 1, _not => 1, _block => $_[5] } }}
Tree       ::= Space $? $? AtId Space Block         {{ shift; return { _if => $_[3], _is_true => 1, _block => $_[5] } }}
Tree       ::= Space $? $? $! AtId Space Block      {{ shift; return { _if => $_[4], _is_true => 1, _not => 1, _block => $_[6] } }}

Block      ::= Space ${ Space Parser Space $} Space {{ shift; return $_[3]; }}
Block      ::= Space $> Space Parser Space          {{ shift; return $_[3]; }}
Block      ::= Space ${ $}                          {{ shift; return []; }}

Attrs      ::= Attr+                                {{ shift; return \@_; }}

Attr       ::= Space Id $= String                   {{ shift; return { _id => $_[1], _string => $_[3] } }}
Attr       ::= Space Id $= AtId                     {{ shift; return { _id => $_[1], _atid => $_[3] } }}

AtId       ::= $@ Id                                {{ shift; return $_[0].$_[1]; }}

String     ::= $" Chars $"                          {{ shift; return {_str => $_[1]} }}

Chars      ::= Null
Chars      ::= Char+                                {{ shift; return join('', @_); }}

Space      ::= Null
Space      ::= WS

Number = /\d+/
Space = /[ \r\n\t]+/

Parser ::= Number WS         {{ return $_[1]; }}
WS     ::= Null
WS     ::= Space

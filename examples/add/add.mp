
Number = /\d+/


Parser ::= Number {{ return $_[1]; }}

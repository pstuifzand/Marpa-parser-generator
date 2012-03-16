# Generates a Marpa parser for parsing Marpa
# Copyright (C) 2011  Peter Stuifzand
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

Name      = /\w+/
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

Parser    ::= Decl+                             {{ return $_[0]; }}
Decl      ::= Rule                              {{ push @{$_[0]->{rules}}, $_[1] }}
Decl      ::= TokenRule                         {{ push @{$_[0]->{tokens}}, $_[1] }}
TokenRule ::= Lhs EQ SLASH RX SLASH             {{ shift; return { @{$_[0]}, regex => qr/$_[3]/ } }}
TokenRule ::= Lhs EQ Char                       {{ shift; return { @{$_[0]}, 'char' => $_[2] } }}
Rule      ::= Lhs DeclareOp Rhs                 {{ shift; return { @{$_[0]}, @{$_[2]} }     }}
Rule      ::= Lhs DeclareOp Rhs CB Code CE      {{ shift; return { @{$_[0]}, @{$_[2]}, code => $_[4] }     }}
Lhs       ::= Name                              {{ shift; return [ lhs => $_[0] ]           }}
Rhs       ::= Names                             {{ shift; return [ rhs => $_[0] ]           }}
Rhs       ::= Names Star                        {{ shift; return [ rhs => $_[0], min => 0 ] }}
Rhs       ::= Names Plus                        {{ shift; return [ rhs => $_[0], min => 1 ] }}
Names     ::= Name+                             {{ shift; return [ @_ ];                    }}


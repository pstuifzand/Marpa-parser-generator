Marpa parser for parsing Marpa
==============================

Synopsys
--------

    # We first need to generate the 'official' parser
    # Which is created from the parser specification

    perl marpa_parser.pl marpa+.mp > gen_marpa.pl

    # This version will create the parser in a package

    mkdir -p lib/MarpaX/Parser

    perl gen_marpa.pl marpa+.mp MarpaX::CodeGen::SimpleLex > lib/MarpaX/Parser/Marpa.pm


    # Which can be used with the 'marp' command

    perl bin/marp [filename] [code_generator] [package...]

    perl bin/marp examples/htmlgen/htmlgen.mp MarpaX::CodeGen::SimpleLex MarpaX::Parser::HTMLGen > lib/MarpaX/Parser/HTMLGen.pm

Description
-----------

### What is this?

This is a program that generates a Marpa::XS::Grammar and lexer from a textual
specification. It uses MarpaX::Simple::Lexer.

Marpa doesn't itself contain a program that creates new parsers from textfiles.
This program first creates a new Marpa parser generator from a textfile
containing a description of a Marpa parser.

### Is this related to Marpa?

Well, not really, only in that it uses this library. It's not an official Marpa
module in any way.

### What is Marpa?

Marpa is a really cool parser written in Perl by Jeffrey Kegler. See
<https://metacpan.org/module/Marpa::XS>.


Author
------
Peter Stuifzand

License
-------
GPLv3+



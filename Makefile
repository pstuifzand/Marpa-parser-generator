all: lib/MarpaX/Parser/Marpa.pm

gen_marpa.pl: marpa_parser.pl marpa+.mp
	perl marpa_parser.pl marpa+.mp > $@

lib/MarpaX/Parser/Marpa.pm: gen_marpa.pl marpa+.mp
	mkdir -p lib/MarpaX/Parser
	perl gen_marpa.pl marpa+.mp MarpaX::CodeGen::SimpleLex > $@


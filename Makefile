all: lib/MarpaX/Parser/Marpa.pm

gen_marpa.pl: marpa_parser.pl marpa+.mp
	perl marpa_parser.pl marpa+.mp > $@

lib/MarpaX/Parser/Marpa.pm: gen_marpa.pl marpa+.mp
	mkdir -p lib/MarpaX/Parser
	perl gen_marpa.pl marpa+.mp MarpaX::CodeGen::SimpleLex > $@


lib/MarpaX/Parser/HTMLGen.pm: examples/htmlgen/htmlgen.mp
	bin/marp $< MarpaX::CodeGen::SimpleLex MarpaX::Parser::HTMLGen > $@

htmlgen: lib/MarpaX/Parser/HTMLGen.pm
	perl examples/htmlgen/htmlgen.pl examples/htmlgen/test.htmlgen


clean:
	-rm lib/MarpaX/Parser/Marpa.pm
	-rm lib/MarpaX/Parser/HTMLGen.pm
	-rmdir --ignore-fail-on-non-empty lib/MarpaX/Parser
	-rm gen_marpa.pl

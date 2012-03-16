
generated_marpa_parser.pl: marpa_parser.pl marpa.mp
	perl -I lib marpa_parser.pl marpa.mp > $@

examples/add/add.pl: generated_marpa_parser.pl examples/add/add.mp
	perl -I lib generated_marpa_parser.pl examples/add/add.mp > $@



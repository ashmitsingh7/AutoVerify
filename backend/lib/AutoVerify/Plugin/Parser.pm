package AutoVerify::Plugin::Parser;
##############################################################################
# AutoVerify::Plugin::Parser - extension point contract (interface only).
#
# A Parser Plugin would let AutoVerify parse dialects the core Parser.pm
# doesn't handle (e.g. non-ANSI headers, VHDL entities). None exist yet;
# this defines the shape a future one must have so the core can load it
# without modification.
#
# Required methods a plugin class must implement:
#   can_parse($source_text)              -> true/false: "is this mine?"
#   parse($source_text, $label)          -> same AST shape as
#                                            AutoVerify::Parser::parse_source
#                                            (module_name, param_order,
#                                            param_default, ports, ...)
##############################################################################
use strict;
use warnings;

sub can_parse { die ref($_[0]) . " must implement can_parse(\$source_text)\n"; }
sub parse     { die ref($_[0]) . " must implement parse(\$source_text, \$label)\n"; }

1;

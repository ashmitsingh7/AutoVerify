package AutoVerify::ParserError;
##############################################################################
# AutoVerify::ParserError - raised while parsing a Verilog/SystemVerilog source file.
# Inherits all fields/behavior from AutoVerify::Error; exists as a distinct
# class so callers can catch/dispatch on error type (e.g. $@->isa('AutoVerify::ParserError')).
##############################################################################
use strict;
use warnings;
use AutoVerify::Error;
use parent -norequire, 'AutoVerify::Error';

1;

package AutoVerify::GeneratorError;
##############################################################################
# AutoVerify::GeneratorError - raised while writing generated output files.
# Inherits all fields/behavior from AutoVerify::Error; exists as a distinct
# class so callers can catch/dispatch on error type (e.g. $@->isa('AutoVerify::GeneratorError')).
##############################################################################
use strict;
use warnings;
use AutoVerify::Error;
use parent -norequire, 'AutoVerify::Error';

1;

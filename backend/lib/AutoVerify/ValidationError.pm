package AutoVerify::ValidationError;
##############################################################################
# AutoVerify::ValidationError - raised for a semantic problem found by AutoVerify::Validation.
# Inherits all fields/behavior from AutoVerify::Error; exists as a distinct
# class so callers can catch/dispatch on error type (e.g. $@->isa('AutoVerify::ValidationError')).
##############################################################################
use strict;
use warnings;
use AutoVerify::Error;
use parent -norequire, 'AutoVerify::Error';

1;

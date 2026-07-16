package AutoVerify::Plugin::Simulator;
##############################################################################
# AutoVerify::Plugin::Simulator - extension point contract (interface only).
#
# For a third-party simulator backend (e.g. Verilator, a cloud sim service)
# shipped outside this repo. Same contract as AutoVerify::Simulator, kept
# as a separate class so plugin authors have a clearly-labeled extension
# point distinct from the built-in Questa/VCS/Xcelium backends.
##############################################################################
use strict;
use warnings;
use AutoVerify::Simulator;
use parent -norequire, 'AutoVerify::Simulator';

1;

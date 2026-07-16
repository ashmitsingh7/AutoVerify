package AutoVerify::Plugin::Generator;
##############################################################################
# AutoVerify::Plugin::Generator - extension point contract (interface only).
#
# A Generator Plugin would add new output artifacts beyond the standard 9
# files (e.g. a UVM-style sequence library, a coverage model). None exist
# yet.
#
# Required methods:
#   additional_files(%ctx) -> { filename => content, ... }
#     %ctx is the same generation context AutoVerify::Renderer receives.
##############################################################################
use strict;
use warnings;

sub additional_files { die ref($_[0]) . " must implement additional_files(%ctx)\n"; }

1;

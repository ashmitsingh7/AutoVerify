package AutoVerify::Plugin::Renderer;
##############################################################################
# AutoVerify::Plugin::Renderer - extension point contract (interface only).
#
# Distinct from AutoVerify::Renderer (the core abstraction Generator.pm
# depends on today, currently backed by ::Renderer::Heredoc). This plugin
# interface is for a *third-party* renderer to register itself without
# editing Generator.pm at all - e.g. a future Template::Toolkit or Jinja
# renderer shipped as a separate CPAN distribution.
#
# Required methods: identical shape to AutoVerify::Renderer's contract.
#   render_all(%ctx) -> { filename => content, ... }
##############################################################################
use strict;
use warnings;
use AutoVerify::Renderer;
use parent -norequire, 'AutoVerify::Renderer';

1;

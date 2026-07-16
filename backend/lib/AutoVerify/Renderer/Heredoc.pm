package AutoVerify::Renderer::Heredoc;
##############################################################################
# AutoVerify::Renderer::Heredoc
#
# Wraps the original heredoc-based CodeGen functions behind the Renderer
# interface. This is what ships today; output is unchanged from the
# monolithic script. Swapping in a Template::Toolkit-backed renderer later
# means writing a new class here, not touching Generator.pm.
##############################################################################
use strict;
use warnings;
use AutoVerify::Renderer;
use parent -norequire, 'AutoVerify::Renderer';

use AutoVerify::CodeGen qw(
    gen_pkg gen_if gen_transaction gen_driver gen_monitor
    gen_scoreboard gen_env gen_tb_top gen_filelist
);

sub render_all {
    my ($self, %ctx) = @_;
    my $module_name = $ctx{module_name};

    return {
        "${module_name}_pkg.sv"         => gen_pkg(%ctx),
        "${module_name}_if.sv"          => gen_if(%ctx),
        "${module_name}_transaction.sv" => gen_transaction(%ctx),
        "${module_name}_driver.sv"      => gen_driver(%ctx),
        "${module_name}_monitor.sv"     => gen_monitor(%ctx),
        "${module_name}_scoreboard.sv"  => gen_scoreboard(%ctx),
        "${module_name}_env.sv"         => gen_env(%ctx),
        "${module_name}_tb_top.sv"      => gen_tb_top(%ctx),
        "${module_name}_files.f"        => gen_filelist(%ctx),
    };
}

1;

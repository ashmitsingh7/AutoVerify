package AutoVerify::Parser;
##############################################################################
# AutoVerify::Parser
#
# Reads a Verilog/SystemVerilog file with an ANSI-style module header and
# returns a plain-hash AST:
#   {
#     module_name   => 'foo',
#     param_order   => [ 'WIDTH', ... ],
#     param_default => { WIDTH => '8', ... },
#     ports         => [ { name, dir, type, width, signed }, ... ],
#   }
#
# Logic here is a straight extraction of gen_tb.pl's original parsing block
# (comment strip -> module header -> optional #(params) -> port list ->
# per-port dir/type/signed/width carry-forward). No behavior was changed.
##############################################################################
use strict;
use warnings;
use Exporter 'import';
use FindBin;
use lib "$FindBin::Bin/../lib";
use AutoVerify::ParserError;

our @EXPORT_OK = qw(parse_file parse_source extract_balanced split_top_level line_col);

sub parse_file {
    my ($verilog_file) = @_;
    AutoVerify::ParserError->throw(
        message => "file not found",
        file    => $verilog_file,
    ) unless -f $verilog_file;

    local $/;
    open(my $fh, '<', $verilog_file) or AutoVerify::ParserError->throw(
        message => "cannot open file: $!",
        file    => $verilog_file,
    );
    my $src = <$fh>;
    close($fh);

    return parse_source($src, $verilog_file);
}

# Given source text and a character offset, return (line, column), both 1-based.
sub line_col {
    my ($src, $pos) = @_;
    my $upto = substr($src, 0, $pos);
    my $line = 1 + ($upto =~ tr/\n//);
    my $last_nl = rindex($upto, "\n");
    my $col = $pos - $last_nl;    # 1-based column after last newline
    return ($line, $col);
}

sub parse_source {
    my ($src, $label) = @_;
    $label //= '<source>';

    $src =~ s{//.*}{}g;
    $src =~ s{/\*.*?\*/}{}sg;

    # -----------------------------------------------------------------------
    # Locate "module <name>" then optional #( params ) then ( ports )
    # -----------------------------------------------------------------------
    $src =~ /\bmodule\s+(\w+)\s*/ or AutoVerify::ParserError->throw(
        message    => "no 'module <name>' found",
        file       => $label,
        suggestion => "check for non-ANSI headers or a missing 'module' keyword",
    );
    my $module_name = $1;
    my $pos = $+[0];

    $pos++ while $pos < length($src) && substr($src, $pos, 1) =~ /\s/;

    my @param_order;
    my %param_default;
    my @malformed_params;    # raw text of any parameter entry that didn't match NAME = VALUE

    if (substr($src, $pos, 1) eq '#') {
        $pos++;
        $pos++ while substr($src, $pos, 1) =~ /\s/;
        if (substr($src, $pos, 1) ne '(') {
            my ($line, $col) = line_col($src, $pos);
            AutoVerify::ParserError->throw(
                message    => "expected '(' after '#' in module header",
                file       => $label, line => $line, column => $col,
                suggestion => "parameter list must be '#( parameter NAME = VALUE, ... )'",
            );
        }
        my ($param_str, $newpos) = extract_balanced($src, $pos, $label);
        $pos = $newpos;

        for my $p (split_top_level($param_str)) {
            $p =~ s/^\s+|\s+$//g;
            next unless length($p);
            my $raw = $p;
            $p =~ s/^parameter\s+//i;
            $p =~ s/^localparam\s+//i;
            # optional type token (int, integer, logic, etc.) before NAME = VALUE
            if ($p =~ /^(?:(?:int|integer|logic|bit|real|string)\s+)?(\w+)\s*=\s*(.+)$/s) {
                my ($name, $val) = ($1, $2);
                $val =~ s/\s+$//;
                push @param_order, $name;
                $param_default{$name} = $val;
            } else {
                push @malformed_params, $raw;
            }
        }
    }

    $pos++ while $pos < length($src) && substr($src, $pos, 1) =~ /\s/;
    if (substr($src, $pos, 1) ne '(') {
        my ($line, $col) = line_col($src, $pos);
        AutoVerify::ParserError->throw(
            message    => "expected '(' for port list",
            file       => $label, line => $line, column => $col,
            suggestion => "ensure the module header is ANSI-style: module name (input ..., output ...);",
        );
    }
    my $port_list_pos = $pos;
    my ($port_str, $newpos2) = extract_balanced($src, $pos, $label);

    # -----------------------------------------------------------------------
    # Parse ports (ANSI style), carrying forward dir/type/signed/width
    # -----------------------------------------------------------------------
    my @ports;
    my ($cur_dir, $cur_type, $cur_signed, $cur_width) = ('input', 'logic', '', '');

    for my $entry (split_top_level($port_str)) {
        my $e = $entry;
        $e =~ s/^\s+|\s+$//g;
        next unless length($e);

        if ($e =~ /^(input|output|inout)\b/i) {
            $cur_dir = lc($1);
            $e =~ s/^(input|output|inout)\b//i;
            $cur_type   = 'logic';
            $cur_signed = '';
            $cur_width  = '';
        }
        $e =~ s/^\s+//;
        if ($e =~ /^(wire|reg|logic|tri)\b/i) {
            $cur_type = lc($1);
            $e =~ s/^(wire|reg|logic|tri)\b//i;
        }
        $e =~ s/^\s+//;
        if ($e =~ /^signed\b/i) {
            $cur_signed = 'signed';
            $e =~ s/^signed\b//i;
        }
        $e =~ s/^\s+//;
        # count leading bracket groups purely for Validation's benefit - the
        # single-width capture below is unchanged, so codegen output (which
        # only ever reads p->{width}) is unaffected.
        my ($lead) = ($e =~ /^((?:\[[^\]]+\])+)/);
        my $bracket_group_count = $lead ? (() = $lead =~ /\[[^\]]*\]/g) : 0;
        if ($e =~ /^(\[[^\]]+\])/) {
            $cur_width = $1;
            $e =~ s/^\[[^\]]+\]//;
        }
        $e =~ s/^\s+|\s+$//g;

        my $name = $e;
        $name =~ s/\[.*\]//g;
        $name =~ s/\s+//g;
        next unless length($name);

        push @ports, {
            name                 => $name,
            dir                  => $cur_dir,
            type                 => $cur_type,
            width                => $cur_width,
            signed               => $cur_signed,
            _bracket_group_count => $bracket_group_count,
        };
    }

    if (!@ports) {
        my ($line, $col) = line_col($src, $port_list_pos);
        AutoVerify::ParserError->throw(
            message    => "no ports parsed",
            file       => $label, line => $line, column => $col,
            suggestion => "non-ANSI port declarations (separate input/output statements) aren't supported - convert the header to ANSI style",
        );
    }

    return {
        module_name      => $module_name,
        param_order      => \@param_order,
        param_default    => \%param_default,
        ports            => \@ports,
        malformed_params => \@malformed_params,
        cleaned_source   => $src,    # comments stripped; used by Validation for construct scanning
    };
}

sub extract_balanced {
    my ($str, $start, $label) = @_;
    $label //= '<source>';
    my $depth = 0;
    my $len   = length($str);
    my $content_start = $start + 1;
    for (my $i = $start; $i < $len; $i++) {
        my $c = substr($str, $i, 1);
        if ($c eq '(') { $depth++; }
        elsif ($c eq ')') {
            $depth--;
            if ($depth == 0) {
                return (substr($str, $content_start, $i - $content_start), $i + 1);
            }
        }
    }
    my ($line, $col) = line_col($str, $start);
    AutoVerify::ParserError->throw(
        message    => "unbalanced parentheses",
        file       => $label, line => $line, column => $col,
        suggestion => "check for a stray '(' or a ')' inside a comment that wasn't stripped",
    );
}

sub split_top_level {
    my ($str) = @_;
    my @parts;
    my $depth = 0;
    my $cur = '';
    for my $ch (split //, $str) {
        if    ($ch =~ /[\(\[\{]/) { $depth++; }
        elsif ($ch =~ /[\)\]\}]/) { $depth--; }
        if ($ch eq ',' && $depth == 0) {
            push @parts, $cur;
            $cur = '';
        } else {
            $cur .= $ch;
        }
    }
    push @parts, $cur;
    return @parts;
}

1;

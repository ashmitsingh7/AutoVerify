package AutoVerify::Validation;
##############################################################################
# AutoVerify::Validation
#
# Semantic checks that run after AutoVerify::Parser has produced an AST.
# Nothing here dies - validate() always returns an arrayref of diagnostics
# (severity 'error' | 'warning', code, message). Callers decide what to do
# with 'error' severity diagnostics (the CLI treats them as fatal; a future
# web backend might return them as JSON instead).
##############################################################################
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(validate);

sub validate {
    my ($ast) = @_;
    my @diags;

    push @diags, _check_duplicate_ports($ast);
    push @diags, _check_duplicate_params($ast);
    push @diags, _check_missing_module_name($ast);
    push @diags, _check_malformed_params($ast);
    push @diags, _check_multidim_packed_arrays($ast);
    push @diags, _check_unsupported_constructs($ast);

    return \@diags;
}

sub _diag {
    my (%a) = @_;
    return { severity => $a{severity} // 'error', code => $a{code}, message => $a{message} };
}

sub _check_duplicate_ports {
    my ($ast) = @_;
    my %seen;
    my @diags;
    for my $p (@{ $ast->{ports} }) {
        $seen{ $p->{name} }++;
    }
    for my $name (sort keys %seen) {
        next unless $seen{$name} > 1;
        push @diags, _diag(
            code    => 'duplicate_port',
            message => "port '$name' declared $seen{$name} times",
        );
    }
    return @diags;
}

sub _check_duplicate_params {
    my ($ast) = @_;
    my %seen;
    my @diags;
    for my $name (@{ $ast->{param_order} }) {
        $seen{$name}++;
    }
    for my $name (sort keys %seen) {
        next unless $seen{$name} > 1;
        push @diags, _diag(
            code    => 'duplicate_parameter',
            message => "parameter '$name' declared $seen{$name} times",
        );
    }
    return @diags;
}

sub _check_missing_module_name {
    my ($ast) = @_;
    return () if defined($ast->{module_name}) && length($ast->{module_name});
    return _diag(code => 'missing_module_name', message => 'module has no name');
}

sub _check_malformed_params {
    my ($ast) = @_;
    my @diags;
    for my $raw (@{ $ast->{malformed_params} || [] }) {
        push @diags, _diag(
            severity => 'warning',
            code     => 'malformed_parameter',
            message  => "parameter entry '$raw' did not match 'NAME = VALUE' and was skipped",
        );
    }
    return @diags;
}

sub _check_multidim_packed_arrays {
    my ($ast) = @_;
    my @diags;
    for my $p (@{ $ast->{ports} }) {
        my $groups = $p->{_bracket_group_count} // 0;
        if ($groups > 1) {
            push @diags, _diag(
                severity => 'warning',
                code     => 'unsupported_multidim_packed_array',
                message  => "port '$p->{name}' has $groups packed dimensions; "
                          . "only the first ($p->{width}) is retained - generator flattens the rest",
            );
        }
    }
    return @diags;
}

sub _check_unsupported_constructs {
    my ($ast) = @_;
    my $src = $ast->{cleaned_source} // '';
    my @diags;

    if ($src =~ /\bgenerate\b/) {
        push @diags, _diag(
            severity => 'warning',
            code     => 'unsupported_generate_block',
            message  => 'source contains a generate block; only the ANSI port list is parsed, generate-block signals are ignored',
        );
    }
    if ($src =~ /\binterface\s+\w+\s*;/ || $src =~ /virtual\s+interface/) {
        push @diags, _diag(
            severity => 'warning',
            code     => 'unsupported_interface_port',
            message  => 'source appears to reference a SystemVerilog interface port; interface-typed ports are not supported by the parser',
        );
    }
    return @diags;
}

1;

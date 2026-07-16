#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use AutoVerify::Parser qw(parse_file parse_source);
use AutoVerify::Error;
use AutoVerify::ParserError;

# --- missing file ---
{
    eval { parse_file('/nonexistent/path/does_not_exist.v') };
    my $err = $@;
    ok($err, 'dies on missing file');
    ok(ref($err) && $err->isa('AutoVerify::ParserError'), 'missing file raises ParserError');
    ok(ref($err) && $err->isa('AutoVerify::Error'), 'ParserError is-a Error (base class)');
    like("$err", qr/file not found/, 'stringified message mentions file not found');
}

# --- no module keyword at all ---
{
    eval { parse_source("just some plain text with no header keyword", 'inline_no_module') };
    my $err = $@;
    ok(ref($err) && $err->isa('AutoVerify::ParserError'), 'missing module keyword raises ParserError');
    like("$err", qr/module <name>/, 'message names the expected construct');
}

# --- unbalanced parens in port list ---
{
    eval { parse_source("module m (input clk, output o", 'inline_unbalanced') };
    my $err = $@;
    ok(ref($err) && $err->isa('AutoVerify::ParserError'), 'unbalanced parens raises ParserError');
    ok(defined $err->line, 'unbalanced-paren error carries a line number');
    ok(defined $err->column, 'unbalanced-paren error carries a column number');
}

# --- missing '(' after # ---
{
    eval { parse_source("module m # input clk;", 'inline_bad_param_header') };
    my $err = $@;
    ok(ref($err) && $err->isa('AutoVerify::ParserError'), q{missing '(' after '#' raises ParserError});
    ok($err->suggestion, 'error includes a suggestion');
}

# --- empty port list (no ports parse out) ---
{
    eval { parse_source("module m ();", 'inline_empty_ports') };
    my $err = $@;
    ok(ref($err) && $err->isa('AutoVerify::ParserError'), 'empty port list raises ParserError');
    like($err->suggestion, qr/ANSI/, 'suggestion mentions ANSI style conversion');
}

# --- Error base class stringification round-trip ---
{
    my $e = AutoVerify::Error->new(message => 'test message', file => 'foo.v', line => 3, column => 7);
    like("$e", qr/foo\.v:3:7/, 'Error stringifies with file:line:col');
    like("$e", qr/test message/, 'Error stringifies with message');
}

done_testing();

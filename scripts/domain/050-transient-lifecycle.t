# -*- perl -*-
#
# Copyright (C) 2009 Red Hat
# Copyright (C) 2009 Daniel P. Berrange
#
# This program is free software; You can redistribute it and/or modify
# it under the GNU General Public License as published by the Free
# Software Foundation; either version 2, or (at your option) any
# later version
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions
#

=pod

=head1 NAME

domain/050-transient-lifecycle.t - Transient domain lifecycle

=head1 DESCRIPTION

The test case validates the core lifecycle operations on
transient domains. A transient domain has no configuration
file so, once destroyed, all trace of the domain should
disappear.

=cut

use strict;
use warnings;

use Test::More tests => 2;

use Sys::Virt::TCK;

my $tck = Sys::Virt::TCK->new();
my $conn = eval { $tck->setup(); };
BAIL_OUT "failed to setup test harness: $@" if $@;
END { $tck->cleanup if $tck; }


my $xml = $tck->generic_domain("test")->as_xml;

diag "Creating a new transient domain";
my $dom;
ok_domain { $dom = $conn->create_domain($xml) } "created transient domain object";

diag "Destroying the transient doamin";
$dom->destroy;

diag "Checking that transient domain has gone away";
ok_error { $conn->get_domain_by_name("test") } "NO_DOMAIN error raised from missing domain", 42;

# end

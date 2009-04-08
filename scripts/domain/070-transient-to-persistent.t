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

domain/070-transient-to-persistent.t - Converting transient to persistent

=head1 DESCRIPTION

The test case validates that a transient domain can be converted
to a persistent one. This is achieved by defining a configuration
file while the transient domain is running.

=cut

use strict;
use warnings;

use Test::More tests => 4;

use Sys::Virt::TCK;

my $tck = Sys::Virt::TCK->new();
my $conn = eval { $tck->setup(); };
BAIL_OUT "failed to setup test harness: $@" if $@;
END { $tck->cleanup if $tck; }


my $xml = $tck->generic_domain("test")->as_xml;

diag "Creating a new transient domain";
my $dom;
ok_domain { $dom = $conn->create_domain($xml) } "created transient domain";

my $livexml = $dom->get_xml_description();

diag "Defining config for transient guest";
my $dom1;
ok_domain { $dom1 = $conn->define_domain($livexml) } "defined transient domain";

diag "Destroying active domain";
$dom->destroy;

diag "Checking that an inactive domain config still exists";
ok_domain { $dom1 = $conn->get_domain_by_name("test") } "transient domain config";

diag "Removing inactive domain config";
$dom->undefine;

diag "Checking that inactive domain has really gone";
ok_error { $conn->get_domain_by_name("test") } "NO_DOMAIN error raised from missing domain", 42;

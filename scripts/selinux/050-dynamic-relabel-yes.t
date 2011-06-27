# -*- perl -*-
#
# Copyright (C) 2009 Red Hat, Inc.
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

domain/050-dynamic-relabel-yes.t - Dynamic label generation with relabelling

=head1 DESCRIPTION

The test case validates that dynamic label generation works,
together with relabelling of resources.

=cut

use strict;
use warnings;

use Test::More tests => 6;

use Sys::Virt::TCK;
use Sys::Virt::TCK::SELinux;

my $tck = Sys::Virt::TCK->new();
my $conn = eval { $tck->setup(); };
BAIL_OUT "failed to setup test harness: $@" if $@;
END { $tck->cleanup if $tck; }

my $info;
eval {
    $info = $conn->get_node_security_model();
};

SELINUX: {
    skip "Only relevant to SELinux hosts", 6 unless $info && $info->{model} eq "selinux";

    my $disk = $tck->create_sparse_disk("selinux", "tck", 50);

    my $origlabel = selinux_restore_file_context($disk);
    diag "Original $origlabel";

    my $xml = $tck->generic_domain("tck")
	->seclabel(model => "selinux", type => "dynamic", relabel => "yes")
	->disk(src => $disk, dst => "vdb", type => "file")
	->as_xml;

    diag "Creating a new transient domain";
    my $dom;
    ok_domain(sub { $dom = $conn->create_domain($xml) }, "created transient domain object");

    my $domainlabel = xpath($dom, "string(/domain/seclabel/label)");
    diag "domainlabel $domainlabel";
    my $imagelabel = xpath($dom, "string(/domain/seclabel/imagelabel)");
    diag "imagelabel $imagelabel";

    is(index($domainlabel, $SELINUX_DOMAIN_CONTEXT), 0, "dynamic domain label prefix is $SELINUX_DOMAIN_CONTEXT");
    is(index($imagelabel, $SELINUX_IMAGE_CONTEXT), 0, "dynamic image label prefix is $SELINUX_IMAGE_CONTEXT");

    my $domainmcs = substr $domainlabel, length($SELINUX_DOMAIN_CONTEXT);
    my $imagemcs = substr $imagelabel, length($SELINUX_IMAGE_CONTEXT);

    is($domainmcs, $imagemcs, "Domain MCS $domainmcs == Image MCS $imagemcs");

    is(selinux_get_file_context($disk), $imagelabel, "$disk label is $imagelabel");

    diag "Destroying the transient domain";
    $dom->destroy;

    is(selinux_get_file_context($disk), $origlabel, "$disk label is $origlabel");
}

# end

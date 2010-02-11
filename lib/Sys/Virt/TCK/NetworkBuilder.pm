package Sys::Virt::TCK::NetworkBuilder;

use strict;
use warnings;
use Sys::Virt;

use IO::String;
use XML::Writer;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $self = {
	name => $params{name} ? $params{name} : "tck" ,
    };

    bless $self, $class;

    return $self;
}

sub bridge {
    my $self = shift;
    my $name = shift;

    $self->{bridge} = { name => $name,
			@_ };

    return $self;
}


sub forward {
    my $self = shift;

    $self->{forward} = { @_ };

    return $self;
}

sub ipaddr {
    my $self = shift;
    my $address = shift;
    my $netmask = shift;

    $self->{ipaddr} = [$address, $netmask];

    return $self;
}

sub dhcp_range {
    my $self = shift;
    my $start = shift;
    my $end = shift;

    $self->{dhcp} = [] unless $self->{dhcp};
    push @{$self->{dhcp}}, [$start, $end];

    return $self;
}

sub as_xml {
    my $self = shift;

    my $data;
    my $fh = IO::String->new(\$data);
    my $w = XML::Writer->new(OUTPUT => $fh,
			     DATA_MODE => 1,
			     DATA_INDENT => 2);
    $w->startTag("network");
    $w->dataElement("name" => $self->{name});

    $w->emptyTag("bridge", %{$self->{bridge}})
	if $self->{bridge};

    $w->emptyTag("forward", %{$self->{forward}})
	if exists $self->{forward};

    if ($self->{ipaddr}) {
	$w->startTag("ip",
		     address => $self->{ipaddr}->[0],
		     netmask => $self->{ipaddr}->[1]);

	if ($self->{dhcp}) {
	    $w->startTag("dhcp");
	    foreach my $range (@{$self->{dhcp}}) {
		$w->emptyTag("range",
			     start => $range->[0],
			     end => $range->[1]);
	    }
	    $w->endTag("dhcp");
	}

	$w->endTag("ip");
    }
    $w->endTag("network");

    return $data;
}

1;

# -*- perl -*-

use Test::More tests => 2;

BEGIN {
      use_ok("Sys::Virt::TCK::StorageVolBuilder");
}


my $xml = <<EOF;
<volume>
  <name>tck</name>
  <capacity>1000000</capacity>
  <allocation>1000000</allocation>
  <target>
    <format type="qcow2" />
    <encryption format="qcow">
      <secret type="passphrase" uuid="0a81f5b2-8403-7b23-c8d6-21ccc2f80d6f" />
    </encryption>
  </target>
</volume>
EOF
chomp $xml;

my $b = Sys::Virt::TCK::StorageVolBuilder->new()
    ->capacity(1000000)->allocation(1000000)
    ->format("qcow2")
    ->secret("0a81f5b2-8403-7b23-c8d6-21ccc2f80d6f")
    ->as_xml;


is ($b, $xml);

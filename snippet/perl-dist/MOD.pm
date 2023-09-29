package {{pkg}};
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.0-prealpha";

use Aion;

has x => (is => "ro", isa => Int);

1;

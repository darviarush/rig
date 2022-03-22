package {{name}};
# 

use common::sense;

sub new {
	my $cls = shift;
	bless {@_}, $cls;
}

1;
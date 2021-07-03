package {{name}};

# 

sub new {
	my $cls = shift;
	bless {@_}, $cls;
}
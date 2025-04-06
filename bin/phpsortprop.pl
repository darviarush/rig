use common::sense;
use open qw/:utf8 :std/;

use Aion::Fs;

replace {
	
	my @mod;
	push @mod, $1 while m!^use[ \t]+(\S+);!gm;
	
	s/\bnew\s+(\w+)\s*\([ \t]*\n(.*\n)[ \t]*\)/ replace_param(\@mod, $1, $2) /ge;
}
find \@ARGV, '*.php';



sub replace_param {
	my ($mod, $class, $params) = @_;

	my @params = split /,[ \t]*\n/, $params;
	
	
	
	join "", map "$_,\n", @params
}
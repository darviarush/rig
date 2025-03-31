use common::sense;
use open qw/:utf8 :std/;

use Aion::Fs;

replace {
	
	s///g;
}
find \@ARGV, '*.php';

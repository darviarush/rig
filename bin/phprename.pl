#!/usr/bin/perl

use common::sense;
use open qw/:std :utf8/;

use Aion::Fs qw/cat find/;

my ($root) = @ARGV;
$root //= $ENV{RIG_PHPRENAME_NAMESPACE} // 'App';

my %renameClass;
my %renameNamespace;

find "src", "*.php", sub {
    replace {
        my ($existsClass, $class, $existsNamespace, $namespace);		
		
		# Класс
        if(/^class\s+(\w+)/m) {
            $existsClass = $1;
            $class = $a =~ m!([^/]+)\.php$!? $1: die "?";
            if ($existsClass ne $class) {
				$renameClass{$existsClass} = $class;
				s/^class\s+$existsClass\b/class $class/m;
            }
        }
        
		# Пространство имён
		if(/^namespace\s+([\w\\]+)/m) {
			$existsNamespace = $1;
			($namespace) = $a =~ m!^src(/.*)/! or die "!";
			$namespace ~= s!/!\\!g;
			$namespace = $root . $namespace;
			if ($existsNamespace ne $namespace) {
				s/^namespace\s+$existsNamespace\b/namespace $namespace/m;
            }
		}
        
		$renameNamespace{"$existsNamespace\\$existsClass"} = "$namespace\\$class" if $class && $namespace && $existsNamespace ne $namespace;
    };
0};

# Второй проход для переименования неймспейсов
find "src", "*.php", sub {
    replace {
		s!^use\s+([\w\\]+)!use ${\($renameNamespace{$1} // $1)}!gm;
    };
0};

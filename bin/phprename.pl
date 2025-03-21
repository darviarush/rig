#!/usr/bin/perl

use common::sense;
use open qw/:std :utf8/;

use Aion::Fs qw/find replace/;

my ($root) = @ARGV;
$root //= $ENV{RIG_PHPRENAME_NAMESPACE} // 'App';

my %renameClass;
my %renameNamespace;

find "src", "*.php", sub {
    replace {
        my ($existsClass, $class, $existsNamespace, $namespace);		
		
		# Класс
        if(/\b(class|enum)\s+(\w+)/m) {
			my $who = $1;
            $existsClass = $2;
            $class = $a =~ m!([^/]+)\.php$!? $1: die "?";
            if ($existsClass ne $class) {
				$renameClass{$existsClass} = $class;
				s/\b$who\s+$existsClass\b/$who $class/m;
            }
        }
        
		# Пространство имён
		if(/^namespace\s+([\w\\]+)/m) {
			$existsNamespace = $1;
			($namespace) = $a =~ m!^src(/.*)/!;
			$namespace =~ s!/!\\!g;
			$namespace = $root . $namespace;
			if ($existsNamespace ne $namespace) {
				s/^namespace\s+${\quotemeta $existsNamespace}\b/namespace $namespace/m;
            }
		}

		$renameNamespace{"$existsNamespace\\$existsClass"} = "$namespace\\$class" if $class && $namespace && $existsNamespace ne $namespace;
    } $_;
0};

use DDP;
print "Переименованы классы:\n";
p %renameClass;
print "Переименованы нэймспейсы:\n";
p %renameNamespace;

# Второй проход для переименования неймспейсов
find "src", "*.php", sub {
    replace {
		s!^use\s+([\w\\]+)!use ${\($renameNamespace{$1} // $1)}!gm;
    } $_;
0};

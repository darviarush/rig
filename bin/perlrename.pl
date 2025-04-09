#!/usr/bin/perl

use common::sense;
use open qw/:std :utf8/;

use Aion::Fs qw/find replace/;
use Aion::Format qw/printcolor warncolor/;

my %renamePkg;
my $debug = 0;

find "lib", "*.pm", sub {
    replace {

        if(/\bpackage\s+(\w:+)/) {
            my $existsPkg = $1;

			my ($pkg) = $a =~ m!^lib/(.*)\.pm$!;
			$pkg =~ s!/!::!g;
 
            if ($existsPkg ne $pkg) {
				$renamePkg{$existsPkg} = $pkg;
				s/\bpackage\s+$existsPkg\b/package $pkg/m;
				printcolor "#red%s#r --> #green%s#r\n", $existsPkg, $pkg;
            }
        } else {
			warncolor "#{red}Нет пакета:#r #gray%s#r\n", $a;
		}
        
    } $_;
0};

my $c; my $f;
# Второй проход для переименования пакетов
find "lib", "*.pm", sub {
	my $i;
    replace {
		s!
			([\w:]+)
		!
			my $pkg = $renamePkg{$1};
			$i++ if defined $pkg;
			$pkg // $1
		!gmxe;
    } $_;
	
	$c += $i;
	$f++ if $i;

0} if keys %renamePkg;

printcolor "#cyan%s#r переименовано #magenta%d#r пакетов в #cyan%d#r файлах\n", $a, $c, $f if $c;
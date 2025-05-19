#!/usr/bin/perl

use common::sense;
use open qw/:std :utf8/;

use Aion::Fs;
use Aion::Format qw/trans/;

my ($path, $txt) = @ARGV;
my ($Name) = $path =~ m!/(\w+)\.php$! or die "Нет имени файла $path";
my $namespace = (($path =~ s/^src/App/r) =~ y!/!\\!r) =~ s!\\[^\\]*$!!r;

my $cases = !$txt? '': (join "", map {
	my ($value, $alias) = split /\t/;
	my $case = $value =~ s/-/_/gr;
	
	<< "END";
    #[Alias('$alias')]
    case $case = '$value';
END
} grep !/^\s*$/, split /\n/, cat $txt);

lay mkpath $path, << "END";
<?php

declare(strict_types=1);

namespace $namespace;

use App\\Enum\\Attribute\\Alias;
use App\\Enum\\Trait\\EnumWithAliasesTrait;

/**
 * .
 */
enum $Name: string
{
    use EnumWithAliasesTrait;
$cases
}
END
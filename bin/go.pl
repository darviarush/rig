#!/usr/bin/perl
# Открывает модуль perl в указанном редакторе

($ed, $pkg, $name) = @ARGV;

$path = $pkg =~ s/::/\//gr . "\.pm";

for(@INC) {
    $f = "$_/$path";
    last if -e $f;
}

die "Нет модуля $mod\n" unless defined $f;

if($name =~ /^\d+$/) { $line = $name }
else {
    $line = 1;
    open f, $f or die "Not open $f: $!\n";

    while(<f>) {
	$line = $., last if /^(sub|has)\s+$name\b/o;
	$line = $., last if /^(my|our)\s+[%\@\$]$name\b/o;
    }
}

%f = (
    mc => 'mcedit %p:%l',
    kate => 'kate -l%l %p',
    npp => "'$ENV{HOME}/.wine/drive_c/Program Files/Notepad++/notepad++.exe' -n%l %p",
    codium => 'codium -g %p:%l',
);
$r = $f{$ed} // "$ed %p:%l";
$r =~ s/%l/$line/;
$r =~ s/%p/$path/;

print $r

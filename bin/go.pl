#!/usr/bin/perl
# Открывает модуль perl в указанном редакторе

($ed, $mod, $name) = @ARGV;

$pkg = $mod;
$name = $', $pkg = $` if $mod =~ /#/;

$path = $pkg =~ s/::/\//gr . "\.pm";

for(@INC) {
    $f1 = "$_/$path";
    $f = $f1, last if -f $f1;
}

warn("Нет модуля $pkg\n"), exit 1 unless defined $f;

if($name eq "") { $line = 1 }
elsif($name =~ /^\d+$/) { $line = $name }
else {
    $line = 1;
    open f, $f or die "Not open $f: $!\n";

    while(<f>) {
	$line = $., last if /^(sub|has|aspect|subtype)\s+[\'\"]?$name\b/o;
	$line = $., last if /^(my|our)\s+[%\@\$]$name\b/o;
    }
}

%f = (
    mc => 'mcedit %p:%l',
    kate => 'kate -l%l %p',
    npp => "'$ENV{HOME}/.wine/drive_c/Program Files/Notepad++/notepad++.exe' -n%l %p",
    codium => 'codium -g %p:%l',
    cd => 'cd %d',
    zed => 'zeditor --goto %p:%l',
);
$r = $f{$ed} // "$ed %p:%l";
$r =~ s!%(.)! $1 eq 'l'? $line: $1 eq 'p'? $f: $1 eq 'd'? ($f =~ s/[^\/]*$//r): "%$1"!ge;


print $r

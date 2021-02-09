#!/usr/bin/perl

use strict;
#use warnings;
use utf8;
use open qw/:utf8 :std/;


# Для ошибок синтаксиса
BEGIN {
	my %HTML_SIM = qw/< &lt; > &gt; & &amp; ' &#39; " &quot;/;
	sub e (@) {
		local $_ = join "", @_;
		s/[<>&'"]/$HTML_SIM{$&}/ge;
		$_
	}
	sub br (@) { 
		local $_=join "", @_;
		s/\n/<br>\n/g;
		s/\t/    /g;
		s/ {2}/ &nbsp;/g;
		$_ 
	}
	$SIG{__DIE__} = sub {
		print "Status: 500 Internal Server Error\n";
		print "Content-Type: text/html; charset=utf8\n\n";
		print "<font color=red>error:</font> ", br e $_[0];
		exit;
	};
}

# $ROOT_DIR и lib
BEGIN {
	$0 =~ m!^(.*)(/[^/]+){3}$! && push @INC, ($::ROOT_DIR = $1) . "/lib";
}

# Ошибки и заголовки
sub __error_block(@_) {
	"<div style='padding: 4px; margin: 4px; border: solid 1px gray; border-radius: 3px'>@_</div>"
}

sub error (@) {
	my $x = $_[1] // "error";
	print __error_block "<font color=red>$x:</font> ", (br e $_[0]);
}

sub header (@) {
	if($::AION_OUTED) { error "Set header (".join("\n", @_)."), but page is printing."; return }
	push @::AION_HEADERS, map { $::AION_CONTENT_TYPE = 1 if /^Content-Type: /i; "$_\n" } @_;
	return;
}


sub redirect(@) {
	header "Status: 303 See Other";
	header "Location: $_[0]";
	header "Content-Type: text/plain; charset=utf8";
	"303) Redirect to $_[0] ..."
}

use DDP {
	colored=>0,
	class=>{
		expand=>'all',
		inherited=>'all'
	},
	deparse=>1,
	show_unicode=>0,
	show_readonly=>1,
	print_escapes=>1,
};
sub show ($) { __error_block br e np(@_) }


# Как что-то будет записано в STDOUT, то это приведёт к записи заголовков
require Tie::Handle;
package AionHeaderHandle;
our @ISA = 'Tie::Handle';

sub TIEHANDLE {
	bless {}, shift;
}

sub WRITE {
	my ($this, $s, $n, $of) = @_;
	untie *STDOUT;
	print @::AION_HEADERS;
	print "Content-Type: text/html; charset=utf8\n" if !$::AION_CONTENT_TYPE;
	print "\n";
	$::AION_OUTED = 1;
	print !defined($n)? $s: substr($s, $of, $n); 
}

# STDERR отправляется на страницу в красивом блоке
package AionErrorHandle;
our @ISA = 'Tie::Handle';

sub TIEHANDLE {
	bless {}, shift;
}

sub WRITE {
	my ($this, $s, $n, $of) = @_;
	::error !defined($n)? $s: substr($s, $of, $n), "STDERR";
}


package main;

tie *STDOUT, 'AionHeaderHandle';
tie *STDERR, 'AionErrorHandle';

# Ошибки синтаксиса - нет и хандлеры установлены
$SIG{__DIE__} = 'DEFAULT';

# Файлы
use File::Slurper qw/read_text write_text/;
sub edit_text (&$) {
	my ($sub, $path) = @_;
	local $_ = read_text $path;
	$sub->();
	write_text $path, $_;
}

# Шаблоны
my %THTML;
my %THTML_CODE;

sub __pkg {
	my $fn = $_[0];
	$fn =~ s!\.thtml$!!;
	$fn =~ s!-!__!g;
	$fn =~ s!/!::!g;
	"render::$fn"
}

sub __color {
	my ($s, $r, $color) = @_;
	$color //= 'red';
	$s =~ s/$r/<font color=$color>$&<\/font>/g;
	$s
}

sub __error (@) {
	my ($path, $e) = @_;

	$e =~ s/\(eval \d+\) /$&$path /g;
	my @lines;
	while($e =~ / line (\d+)/g) { push @lines, $1 }
	my $i=0;
	my $code = File::Slurper::read_text $path;
	$code = e $code;
	$code =~ s!^!sprintf "<font color=red>%02i</font> &nbsp; &nbsp;", ++$i!gme;

	$code =~ s!^<font color=red>${\sprintf "%02i", $_}</font>.*!<span style='background: lightblue'>$&</span>!m for @lines;

	__error_block
		__color((br e $path), qr/.*/),
		": ", 
		__color((br e $e), qr/\d+/),
		"<br><br>",
		br $code;
}

sub render {
	my $path = shift;

	$path =~ s!\.thtml$!!g;

	my $sub = $THTML{$path};
	return $sub->(@_) if defined $sub;

	my $rpath = "$::ROOT_DIR/pleroma/$path.thtml";
	local $_ = read_text $rpath;

	# Если режим разработки, то добавляем теги для dev-редактора
	my $dev = $main_config::dev;

	# Счётчик тегов
	my $counter = 0;

	my $sid = sub { $dev? " sid=\"$path-".(++$counter)."\"": "" };

	my $special_tag;
	my %SPECIAL_TAG = map { $_ => 1 } qw/ script style /;

	my $gen = sub {
		exists $+{perl}? do {
			my ($perl, $space) = @+{qw/perl space/};
			# <% tag "x/y" ... %>
			$perl =~ s/^\s*tag\b//?
				"'; ${space}push \@R, render $perl, content => do { my \@R; push \@R, '" 
					#. ($dev? "<content>": "")
				:
			# <% end %>
			$perl =~ /^\s*end\s*$/?
					#($dev? "</content>": "") . 
				"'; ${space}join '', \@R }; push \@R, '":
			# <% include "x/y", x=>10... %>
			$perl =~ s/^\s*include\b//?
				"'; push \@R, ${space}render $perl; push \@R, '":
			# <% ... %>
			($dev? "<perl${\$sid->()} perl=\"".e($perl)."\"></perl>": "") . "'; $space$perl; push \@R, '"
		}:
		exists $+{exp}?
			($dev? "<exp${\$sid->()} perl=\"".e($+{exp})."\">": "") . 
				"'; $+{space}push \@R, e(do {$+{exp}}); push \@R, '" . 
			($dev? "</exp>": ""):
		exists $+{hexp}? 
			($dev? "<inline${\$sid->()} perl=\"".e($+{hexp})."\">": "") . 
				"'; $+{space}push \@R, do {$+{hexp}}; push \@R, '" .
			($dev? "</inline>": ""):
		exists $+{exp_s}?
			"', do{ $+{exp_s} }, '":
		exists $+{tag}? do {
			my $res = "<$+{tag}";
			$res .= $sid->() if !defined $special_tag;
			$special_tag = $+{tag} if $SPECIAL_TAG{$+{tag}};
			$res
		}:
		exists $+{tag_end}?
			">":
		exists $+{tag_close}? do {
			undef $special_tag if $+{tag_close} eq $special_tag;
			"</$+{tag_close}>"
		}:
		exists $+{quot}? "\\'":
		die "?";
	};

	s{
			(?<space>(^|\n) [ \t]*) %== (?<hexp>[^\n]* )
		| 	(?<space>(^|\n) [ \t]*) %= (?<exp>[^\n]* )
		| 	(?<space>(^|\n) [ \t]*) %\# (?<comment>[^\n]* )
		| 	(?<space>(^|\n) [ \t]*) % (?<perl>[^\n]* )
		|	<%== (?<hexp>.*?) %>
		|	<%= (?<exp>.*?) %>
		|	<% (?<perl>.*?) %>
		|   \{\{ (?<exp_s> .*?) \}\}
		|	< (?<tag> \w+)
		|	(?<tag_end> >)
		|	</ (?<tag_close> \w+) >
		|	(?<quot>')
	}{
		$gen->()
	}igenxs;

	my $pkg = __pkg($path);

	#$_ = "<render path=\"".e($path)."\">$_</render>" if $dev;

	my $code = "use strict; use warnings; use utf8; sub $pkg { my \$x = eval { my %kw = \@_; my \@R; push \@R, \'$_\';
		join '', \@R;
	};
	return __error('$rpath', \$@) if \$@;
	\$x
}

1;";

	if($main_config::render_dump) {
		print br e $code;
		print "<br><br>";
	}

	$THTML_CODE{$path} = $code;
	eval $code;	
	return __error $rpath, $@ if $@;

	return ($THTML{$path} = \&{$pkg})->(@_);
}

sub render_init {
	$main_config::dev? "
<style>
exp, inline, render, content {display: block}
</style>
": ""
}

# Роутинг
eval {
	require main_config;
	require user_config if -e "$::ROOT_DIR/lib/user_config.pm";


	# База
	use DBI;
	$::base = DBI->connect($main_config::base_dsn, $main_config::base_user, $main_config::base_password, {
		'RaiseError' => 1,
		'mysql_enable_utf8 => 1',
	});
	$::base->do($_) for @$main_config::base_options;
	END {
		$::base->disconnect if $::base;
	}
	sub query_ref(@) {
		my ($query, %kw) = @_;
		$query =~ s!:(\w+)!$::base->quote($kw{$1})!ge;
		if($query =~ /^\s*(select|show)\b/in) {
			my $sth = $::base->prepare($query);
			$sth->execute;
			my $r = [];
			while(my $x = $sth->fetchrow_hashref) { push @$r, $x; }
			$sth->finish;
			$r
		} else {
			$::base->do($query) + 0
		}
	}
	sub query(@) {
		my $ref = query_ref(@_);
		ref $ref? @$ref: $ref
	}


	require routers;
	require Aion::Request;
	our $request = Aion::Request->new(%ENV)->init;
	#our $request = CGI::

	my $uri = $request->path;

	my $i = 0; my $flag;
	for my $router (our @ROUTERS) {
		if($i++ % 2 == 0) {
			$flag = $uri =~ $router;
			$request->{SLUG} = {%+};
		}
		elsif($flag) {
			print render $router;
			print render "aion-editor/main" if $main_config::dev;
			goto END;
		}
	}

	header "Status: 404 Not Found";
	print "404 Not Found";
	END:
};
if($@) {
	header "Status: 500 Internal Server Error";# if !$::AION_OUTED;
	print "<div><font color=red>die:</font> ", br(e $@), "</div>";
}


# print "Content-Type: text/html; charset=utf8\n\n";


# print "REQUEST_URI=$ENV{REQUEST_URI}  $uri<br>\n";
# print "x=${\`pwd`} $0<br>\n";
# print "<br>\n";



# for (sort keys %ENV) {
# 	print "$_=$ENV{$_}<br>\n";
# }

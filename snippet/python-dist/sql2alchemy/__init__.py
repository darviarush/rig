''' Переводит текст из sql в sqlalchemy '''

import os
import os.path
import re
import sys

def fsql2alchemy(sql_file, file=None, model=None):
    with open(sql_file, "r") as f:
        return sql2alchemy(f.readlines(), file, model, sql_file)


COMMENT = r''' "(?:""|[^"])*" | '(?:''|[^'])*' '''


def sql2alchemy(sql, file=None, model=None, out_file=None):
	
	import_sql = {}
	import_dialect = {}
	
	tab_match = re.match(r'create\s+table\s+`?(\w+)`?', re.I)
	
	$file = app->magnitudeLiteral->to_snake_case($tab) if !defined $file;
	$model = app->magnitudeLiteral->toCamelCase($file) if !defined $model;
	
	
	
	sub comment {
        local $_ = $_[0];
        my ($f) = /^(.)/;
        s/^$f(.*)$f$/$1/;
        s/$f$f/$f/g;
        s!"!\\"!g;
        "\"$_\""
	}
	
	S = qr/[\ \t]/x;
	
	my $tab_comment = comment($sql =~ /COMMENT=($COMMENT)\s*$/i);
	
	my %key;
	while($sql =~ m!
        ^ $S* ( (?<unique>UNIQUE $S+)|(?<primary>PRIMARY $S+) )? KEY(\s+(`(?<name>\w+)`)|(?<name>\w+))?\s*\(\s*(?<keys>[^()]*)\s*\)?!mgxin) {
        my ($primary, $unique) = @+{qw/primary unique/};
        for(split /\s*,\s*/, $+{'keys'}) {
            s/`//g;
            $key{$_}->{unique}++ if $unique;
            $key{$_}->{primary}++ if $primary;
            $key{$_}->{'index'}++ if !$primary && !$unique;
        }
	}
	
	#CONSTRAINT `order_cancellation_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `Ru_Order_General` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
	my %fk;
	while($sql =~ m!^ $S* CONSTRAINT \s+ (`(?<name>\w+)` | (?<name>\w+)) \s+
        FOREIGN \s+ KEY \s+ \( \s* `(?<col>\w+)` \s* \) \s*
        REFERENCES \s* `(?<ref_tab> \w+)` \s* \( \s* `(?<ref_col> \w+)` \s* \) \s* 
        (ON \s+ DELETE \s+ (?<delete>\S+) \s* )?
        (ON \s+ UPDATE \s+ (?<update>\S+) \s* )?
        [,\)]
	!mgxin) {
        push @{ $fk{$+{col}} }, join "", "ForeignKey(", app->magnitudeLiteral->toCamelCase($+{ref_tab}).".".$+{ref_col},
            $+{'delete'}? ", ondelete='$+{delete}'": (),
            $+{update}? ", onupdate='$+{update}'": (),
        ")";
	}
	
	msg1 \%fk;
	
	my $cols = [];
	while($sql =~ m!
        ^ $S* (`(?<col>\w+)` | (?<col>\w+)) 
            $S+ (?<type> \w+) ($S* \($S* (?<precision>\d+($S*, $S*\d+)? ) $S* \) )?
            (?<unsigned> $S* unsigned )? 
            (?<not_null> $S* not)? ($S*null)? 
            (?<autoincrement> $S* AUTO_INCREMENT)?
            ($S* DEFAULT $S* (?<default> \S+ ))?
            (?<on_update> \s+ ON \s+ UPDATE \s+ CURRENT_TIMESTAMP )?
            ($S* COMMENT $S* (?<comment> $COMMENT ))?
	!imsgxn) {
	
        my $col = uc $+{col};
        next if grep { $col eq $_ } qw/CREATE PRIMARY UNIQUE/;
	
        my $precision = $+{precision};
        my $type = uc $+{type};
        $type = $type eq "INT"? "INTEGER": $type;
        $type =
            $type eq "TINYINT" && $precision eq 1? do { $import_sql{"Boolean"}=1; undef $precision; "Boolean" }:
            $type eq "VARCHAR"? do { $import_sql{"String"}=1; "String" }:
            $type eq "DATETIME"? do { $import_sql{"DateTime"}=1; $precision = "timezone=True"; "DateTime" }:
            do { $import_dialect{$type}=1; $type };
        #msg1 $type, {%+};
        push @$cols, join "", "$+{col} = Column(",
            join(", ",
                join("", $type, "(", $precision, $+{unsigned}? ", unsigned=True": "", ")"),
                exists $fk{$+{col}}? join("", @{$fk{$+{col}}}): (),
                $+{not_null} && !exists $key{$+{col}}->{primary}? "nullable=False": (),
                exists $key{$+{col}}->{primary}? "primary_key=True": (),
                $+{autoincrement}? "autoincrement=True": (),
                exists $key{$+{col}}->{unique}? "unique=True": (),
                exists $key{$+{col}}->{'index'}? "index=True": (),
                $+{default} eq "CURRENT_TIMESTAMP"? do {
                    $import_sql{"func"}=1;
                    "server_default=func.now()"
                }:
                $+{default} && uc($+{default}) ne "NULL"? do {
                    $import_sql{"text"}=1;
                    "server_default=text(" . app->magnitudeLiteral->to($+{default}) . ")"
                }: (),
                $+{on_update}? do { $import_sql{func}=1; "onupdate=func.now()" }: (),
                "comment=".comment($+{comment}),
            ),
        ")";
	}
	
	$cols = join "\n    ", @$cols;
    
	my ($engine) = $sql =~ /ENGINE=(\w+)/i;
	my ($charset) = $sql =~ /DEFAULT CHARSET=(\w+)/i;
	my $collate = "${charset}_general_ci";
	
	my $import_sql = join "", map { ", $_" } sort keys %import_sql;
	my $import_dialect = %import_dialect? "\nfrom sqlalchemy.dialects.mysql import " . join(", ", sort keys %import_dialect): "";
	
	app->file($f)->ext(".py")->write(<<"END");
"""
NAME
====
$file — модель $model таблицы $tab

VERSION
=======
0.49.0

SYNOPSIS
========

    from ccxx.db import DB
    from ccxx.base.$file import $model

    db = DB('host', 'user', 'password', 'database')
    session = db.get_session()
    data = session.query($model).all()

    session.close()


DESCRIPTION
===========
Модель предназначена для работы с таблицей '$tab' базы данных "220_volt"

MODELS
======
"""
from sqlalchemy import Column$import_sql$import_dialect

from .base_model import BaseModel


class $model(BaseModel):
    """
    Модель таблицы $tab
    """
    __tablename__ = '$tab'
    __table_args__ = {'mysql_engine': '$engine',
                      'mysql_charset': '$charset',
                      'mysql_collate': '$collate',
                      'comment': $tab_comment}

    $cols
END
}

#!/bin/bash

# Развернуть указанный сниппет в текущий каталог
#
#   mk сниппет название_без_расширения [FLAT]
#
# $1 — сниппет
# $2 — название файла
# $3 — если сниппет - каталог, то не вкладывать результат в каталог

export name=$2
export Name=${2^}
export NAME=${2^^}

# Смотрим, где в пути к каталогу lib и от неё создаём 
export PACKAGE=

export timestamp=`date +%Y%m%d%H%M%S`
export pkg=$2
export xpkg=`echo "$pkg" | sed 's/python_//g'`
export pypkg=`echo "$pkg" | sed 's/-/_/g' | sed 's/python_//g'`
export Pypkg=${pypkg^}
snippet=$RIG_RC/snippet/$1

if [ -z "$3" ]; then FLAT=$pkg; else FLAT="."; fi

echo "***************************************"
echo "** $snippet"
echo "***************************************"

replace_vars() {
	perl -npe 's!\{\{(\w+)(^^?)?\}\}! $x = $ENV{$1} // $&; $2 eq "^"? ucfirst $x: $2 eq "^^"? uc $x: $x!ge'
}

cp_path() {
	path=$1
	to=`echo $FLAT${1#$snippet}`

	if [ $to == . ]; then return; fi

	to=`echo $to | replace_vars`

	echo $to

	if [ -e $to ]; then
		echo "Файл существует."
		exit 1
	fi

	if [ -f $path ]; then
		cat $path | replace_vars > $to
	elif [ -d $path ]; then
		mkdir -p $to
	else
		echo "Странный путь `$path`"
	fi
}

if [ -d $snippet ]; then
	find $snippet | while read file; do cp_path "$file"; done
else
	cp_path $snippet.*
fi


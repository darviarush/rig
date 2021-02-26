#!/bin/bash

# Развернуть указанный сниппет в текущий каталог

export pkg=$2
export xpkg=`echo "$pkg" | sed 's/python_//g'`
export pypkg=`echo "$pkg" | sed 's/-/_/g' | sed 's/python_//g'`
snippet=$RIG_RC/snippet/$1

echo "***************************************"
echo "** $snippet"
echo "***************************************"

replace_vars() {
	perl -npe 's!\{\{(\w+)\}\}!$ENV{$1} // $&!ge'
}

cp_path() {
	path=$1
	to=`echo $pkg${1#$snippet}`
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

find $snippet | while read file; do cp_path "$file"; done

#!/bin/bash

# Развернуть указанный сниппет в текущий каталог

export pkg=`basename "$(pwd )"`
export pypkg=`echo "$pkg" | sed 's/-/_/g'`
snippet=$RIG_RC/snippet/$1

replace_vars() {
	perl -npe 's!\{\{(\w+)\}\}!$ENV{$1} // "???"!ge'
}

cp_path() {
	path=$1
	to=`echo $1 | sed 's/^$snippet//'`
	to=`echo $to | replace_vars`

	if [ -f $path ]; then
		cat $path | replace_vars > $to
	else
		mkdir -p $to
	fi 
}

find $snippet -exec cp_path "{}" \;

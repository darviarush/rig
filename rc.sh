#!/bin/bash
#
# Автоматизатор задач
#
# Выполните:
#
# $ . ./rc.sh startup
#
# для добавления задач в bash

export EDITOR=mcedit

if [ "$1" == startup ]; then

	echo "export RIG_RC='`pwd`'" >> ~/.bashrc
	echo '. $RIG_RC/rc.sh' >> ~/.bashrc

	echo "Установлено"
fi


# fn - отредактировать rig/rc.sh и внести его в bash
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh; push fn; popd'


# help - показать список целей
help() {
	grep -e "^#" $RIG_RC/rc.sh | tail -n +2 | sed "s/^#[ \\t]\?//" 
	echo
}


# branch - показать текущую ветку
branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}


# run - показать код bash и выполнить его
run() {
	echo "$1"
	eval "$1"
}


# push - делает комит текущей ветки
push() {
	branch=`branch`
	run "git add ."
	run "git commit -am \"$branch ${1:-save}\""
	run "git pull origin $branch"
	run "git push origin $branch"
}


# pull - пулл текущей ветки
pull() {
	branch=`branch`

	if [ "`git status -s`" != "" ]; then
		is_new=true
		run "git add ."
		run "git commit -am \"$branch ${1:-save}\""
	fi

	git pull origin $branch

	if ["$is_new" != ""]; then git push origin $branch; fi

	if [ "`git status -s`" == "" ]
	then cp -ra etc/sublime-text-3 ~/.config/sublime-text-3
	fi
}


# sta - показать git-статус 
alias sta="git status -s"


# reset - удалить изменения в файлах
alias reset='git reset --hard HEAD'



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
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh; mkdir -p etc/sublime-text-3/; cp -a ~/.config/sublime-text-3/Packages/User/* etc/sublime-text-3/; push fn; popd'


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

	#if [ "`git status -s`" == "" ]
	#then cp -ra etc/sublime-text-3 ~/.config/sublime-text-3
	#fi
}


# sta - показать git-статус 
alias sta="git status -s"


# reset - удалить изменения в файлах
alias reset='git reset --hard HEAD'

# install_pip - установить pip с инета
alias install_pip='curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && python3 /tmp/get-pip.py'

# github - клонировать с github мой проект
github() {
    git clone git@github.com:darviarush/$1.git
}

# mk snippet - выполняет скрипт из каталога snippet
mk() {
    x=$1
    shift
    . $RIG_RC/snippet/$x.sh $*
}

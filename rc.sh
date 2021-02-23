#!/bin/bash
#
# Автоматизатор задач
#
# Выполните:
#
# $ . ./rc.sh startup
#
# для добавления задач в bash

export LANG=ru_RU.UTF-8
export LANGUAGE=ru_RU:ru
export EDITOR=mcedit

if [ "$1" == startup ]; then

	echo "export RIG_RC='`pwd`'" >> ~/.bashrc
	echo '. $RIG_RC/rc.sh' >> ~/.bashrc

	echo "Установлено"
fi


# fn - отредактировать rig/rc.sh и внести его в bash
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh; mkdir -p etc/sublime-text-3/; cp -f -a ~/.config/sublime-text-3/Packages/User/* etc/sublime-text-3/; push fn; popd'


# help - показать список целей
help() {
	grep -e "^#" $RIG_RC/rc.sh | tail -n +2 | sed "s/^#[ \\t]\?//" 
	echo
}


# branch - показать текущую ветку
branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}


# run code - показать код bash и выполнить его
run() {
	echo "$*"
	eval "$*"
	if [ "$?" != 0 ]; then echo "Завершение команды: $?. Выходим"; exit; fi
}

git_diff() {
    m=`git status -s`
    if [ "$m" != "" ]; then
	git status -s
	select i in "Комитим" "Ресетим" "Пропускаем" "Отмена"
	do
	    if $REPLY == 1; then read -p "Введите комментарий: " a; run git add .; run git commit -am "$a"
	    elif $REPLY == 2; then run git reset --hard HEAD
	    elif $REPLY == 3; then echo "Пропущено"
	    else exit
	    fi
	done
    fi
}

# co branch - переключение на ветку
alias co='git checkout'

# new branch - создаёт ветку
new() {
    git_diff
    run git checkout master
    run git pull origin master
    branch=`echo "$1" | awk '{print $1}'`
    if [ "$branch" == "" ]; then echo "Нет бранча!"; exit; fi
    git config branch.$branch.description "$1"
    run git checkout -b $branch
    run git push origin $branch --no-edit
}

# push [comment] - делает комит текущей ветки
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

	git pull origin $branch --no-edit

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

# cdx - cd to astrobook
alias cdx='cd ~/__/astrobook'

# mk snippet - выполняет скрипт из каталога snippet
mk() {
    x=$1
    shift
    . $RIG_RC/snippet/$x.sh $*
}

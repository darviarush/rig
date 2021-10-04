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
export PATH=$PATH:/usr/sbin

if [ "$1" == startup ]; then

	echo "export RIG_RC='`pwd`'" >> ~/.bashrc
	echo '. $RIG_RC/rc.sh' >> ~/.bashrc

	echo "Установлено"
fi

alias ls='ls --color'

# fn - отредактировать rig/rc.sh и внести его в bash
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh; mkdir -p etc/sublime-text-3/; rsync -ravh ~/.config/sublime-text-3/Packages/User/ etc/sublime-text-3/; push fn; popd'

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
	#if [ "$?" != 0 ]; then echo "Завершение команды: $?. Выходим"; fi
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
	    else return 1
	    fi
	done
    fi
}

# co branch - переключение на ветку
alias co='git checkout'

# desc - описание текущего бранча
alias desc='git config branch.`branch`.description'

# new branch - создаёт ветку
new() {
    if "`git_diff`" == 1; then return; fi
    run git checkout master
    run git pull origin master
    branch=`echo "$1" | awk '{print $1}'`
    if [ "$branch" == "" ]; then echo "Нет бранча!"; fi
    git config branch.$branch.description "$1"
    run git checkout -b $branch
    run git push origin $branch
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
		is_new="true"
		run "git add ."
		run "git commit -am \"$branch ${1:-save}\""
	fi

	git pull origin $branch --no-edit

	if [ "$is_new" != "" ]; then git push origin $branch; fi

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

# cda - cd to astrobook
alias cda='cd ~/__/astrobook'

# cde - cd to erswitcher
alias cde='cd ~/__/erswitcher'

# cdn - cd to ninjs
alias cdn='cd ~/__/ninja'


# npp - запустить notepad++ в новом окне
alias npp='~/.wine/drive_c/Program\ Files/Notepad++/notepad++.exe -multiInst &> /dev/null &'

# vg - перейти в каталог ~/_vg и запустить vagrant
vg() {
    pushd ~/_vg
    vagrant $*
    popd
}

# mk snippet name - копирует сниппет с подстановками в текущий каталог
alias mk='$RIG_RC/bin/mk.sh'

# py_test - тестирует пакет питон в текущей папке с покрытием
py_test() {
    pypkg=`basename $(pwd )`
    pypkg=`echo "$pypkg" | sed 's/-/_/g' | sed 's/python_//g'`
    rm -fr htmlcov
    PYTHONPATH=. coverage run --branch --source=$pypkg -m pytest tests/ && coverage report -m && coverage html && \
        if [ "$1" == "open" ]; then xdg-open htmlcov/index.html; fi
}

# py_upload - загружает текущий репозиторий питон как пакет в pypi
alias py_upload='py_test && push dist && $RIG_RC/bin/pypi.org.upload.sh'

# py_upload_only - загружает текущий репозиторий питон как пакет в pypi не тестируя его и не пуша
alias py_upload_only='$RIG_RC/bin/pypi.org.upload.sh'

# py_init - настраивает консоль на работу с pyenv
py_init() {
    export PATH="~/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
}

# portal - подключение по ssh для нестандартного порта
alias portal='ssh -p 6022 '

# defopt - установить опции окружения по умолчанию
defopt() {
	xdg-settings set default-web-browser opera.desktop
}

# gitconf - конфигурирует git
gitconf() {
	git config --global pull.rebase false   # rebase
	git config --global pull.ff only       # fast-forward only
}

# installrig - 		инсталлирует самое необходимое
installrig() {
    pamac install aspell hspell libvoikko kcompare
}

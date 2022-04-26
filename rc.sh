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
export PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[31m\]$(branch_prompt )\[\033[01;32m\]]\$\[\033[00m\] '

if [ "$1" == startup ]; then

    for i in ~/.bashrc ~/.zshrc; do
	if [ -e $i ]; then
	    perl -i -0pe 's/$/\n\nexport RIG_RC=${\`pwd`}. $RIG_RC\/rc.sh/ if !/^export[ \t]+RIG_RC=/m' $i
	    echo "Установлено в $i"
	fi
    done
fi

alias ls='ls --color'

# fn - отредактировать rig/rc.sh и внести его в bash
## mkdir -p etc/sublime-text-3/; rsync -ravh ~/.config/sublime-text-3/Packages/User/ etc/sublime-text-3/;
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh;  push fn; popd'

# help - показать список целей
help() {
	grep -e "^#" $RIG_RC/rc.sh | tail -n +2 | sed "s/^#[ \\t]\?//" 
	echo
}


# run code - показать код bash и выполнить его
run() {
	echo "$*"
	eval "$*"
	c="$?"
	if [ "$c" != 0 ]; then echo "Завершение команды: $c. Выходим"; fi
}

git_diff() {
    m=`git status -s`
    if [ "$m" != "" ]; then
		git status -s
		PS3="Ваш выбор:"
		select i in Комитим Ресетим Пропускаем Отмена
		do
	    	case $i in
				Комитим) read -p "Введите комментарий: " a; run git add .; run git commit -am "$a";;
				Ресетим) run git reset --hard HEAD;;
				Пропускаем) echo "Пропущено";;
				Отмена) return 1;;
	    	esac
		done
    fi
    return 0
}


# desc - описание текущего бранча
alias desc='git config branch.`branch`.description'

# new branch - создаёт ветку
new() {
    if "`git_diff`" == 1; then return; fi
    run git checkout master
    run git pull origin master
    local b=`echo "$1" | awk '{print $1}'`
    if [ "$b" == "" ]; then echo "Нет бранча!"; return; fi
    local s="`echo "$1" | sed -r 's/^\S+\s*//'`"
    git config --global merge.branchdesc true
    git config branch.$b.description "$s"

    run git checkout -b $b
    git merge --log
    run git push origin $b
}

# branch - показать текущую ветку
branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# branch_prompt - показать ветку красной и с отступом в пробел, если есть
branch_prompt() {
	b=`branch`
	if [ "$b" != "" ]; then echo " $b"; fi
}

# c0 branch - переключение на ветку
c0() {
    if git_diff; then
        git checkout $1
    fi
}


# bdiff - сравнение двух бранчей. Выполните installrig или установите kompare
bdiff() {
    if [ "$1" == "" ]; then branch=`branch`; else branch=$1; fi
    git diff master...$branch | kompare -
}

# commit - комитит. Если нечего комитить - ничего не делает
commit() {
    if [ "`sta`" != "" ]; then
    	sta
        run "git add ."
        run "git commit -am \"`branch` ${1:-`desc`}\""
    fi
}

# upd - обновить ветку с мастера
upd() {
    run "git merge origin/master --no-edit --no-ff"
}

# push [comment] - делает комит текущей ветки
push() {
	branch=`branch`
	if [ "$1" == 1 ]; then commit "`desc`"; else commit "$1"; fi
	run "git pull origin $branch --no-edit || git merge --no-ff origin/$branch"
	run "git push origin $branch"
}

# pull - пулл текущей ветки
pull() {
	branch=`branch`

	if [ "`sta`" != "" ]; then
	    sta
	    echo
	    echo "Вначале запуште."
	    return 1
	fi

	run "git pull origin $branch --no-edit || git merge --no-ff origin/$branch"
}

# merge - мержит текущую ветку с мастером и удаляет её
merge() {
	local b="`branch`"
	echo "=== merge $b ==="
    run "c0 master"
    run "git merge --no-ff $b"
    run "push 'Слияние $b \"`desc`\"'"
	if [ "$1" == "" ]; then
		echo "=== Удаление $b ==="
		run "git push origin :$b"
		run "git branch -D $b"
	fi
}

# sta - показать сокращённый git-статус
alias sta="git status -s"

# sta1 - показать git-статус
alias sta1="git status"

# reset - удалить изменения в файлах
alias reset='git reset --hard HEAD'

# release version-message - ставит тег и меняет версию в README.md
release() {
    if [ "`branch`" != master ]; then echo "Вначале перейдите на master"; return; fi

    ver=`echo "$1" | awk '{print $1}'`
    if [ "$ver" == "" ]; then echo "Нет версии!"; return; fi
    desc="`echo "$1" | sed -r 's/^\S+\s*//'`"
    if [ "$desc" == "" ]; then echo "Нет описания!"; return; fi

    perl -i -np -e 's/^(#+[ \t]+VERSION\s*)\S+/$1$ver/m' README.md
    return

    commit "Релиз версии $ver"

    git tag -a "$ver" -m "$desc"
    git push origin --tags
}

# version - версия из README.md текущего проекта
version() {
    perl -e '$_=join "", <>; print("$1\n") if /^#+[ \t]+VERSION\s+(\S+)/m' README.md
}

# github name - клонировать с github мой проект
github() {
    git clone git@github.com:darviarush/$1.git
}

# install_pip - установить pip с инета
alias install_pip='curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && python3 /tmp/get-pip.py'


# cda - cd to astrobook
alias cda='cd ~/__/astrobook'

# cde - cd to erswitcher
alias cde='cd ~/__/erswitcher'

# cdn - cd to ninja
alias cdn='cd ~/__/ninja'

# cds - cd to sua-basic
alias cdmx='cd ~/__/mx-basic'

# cdth - cd to ethereal-theory
alias cdth='cd ~/__/ethereal-theory'


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
    pamac install aspell hspell libvoikko kompare
}

#!/bin/bash
#
# Автоматизатор задач
#
# Выполните:
#
# $ . ./rc.sh startup
#
# для добавления задач в bash

#@category rc

export LANG=ru_RU.UTF-8
export LANGUAGE=ru_RU:ru
export EDITOR=mcedit
export PATH=$PATH:/usr/sbin:`shopt -s nullglob; echo ~/__/@lib/*/script | sed 's/ /:/g'`
export PERL5LIB=lib:`shopt -s nullglob; echo $PERL5LIB ~/__/@lib/*/lib | sed 's/ /:/g'`
export PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[31m\]$(branch_prompt )\[\033[01;32m\]]\$\[\033[00m\] '


if [ "$1" == startup ]; then

    for i in ~/.bashrc; do
        if [ -e $i ]; then
            perl -i -0pe 's/$/\n\nexport RIG_RC=${\`pwd`}. \$RIG_RC\/rc.sh/ if !/^export[ \t]+RIG_RC=/m' $i
            echo "Установлено в $i"
        fi
    done
fi

alias ls='ls --color'

# fn - отредактировать rig/rc.sh и внести его в bash
## mkdir -p etc/sublime-text-3/; rsync -ravh ~/.config/sublime-text-3/Packages/User/ etc/sublime-text-3/;
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh; push fn; popd'

# help - показать список целей
help() {
    if perl -V > /dev/null; then
        perl  -e '
        use Term::ANSIColor qw/colored :constants/;
        while(<>) {
            print(colored("「$1」", "bold red"), "\n"), next if /#\@category\s+(.*)/;

            next unless /^# /;

            /^#\s+(\S+)(?:\s+((?:[^-]|\S-)+?))?\s+-\s+(.*)/ or do { print s/^# //r, "\n"; next; };

            print colored(sprintf("   %15s", $1), "bold green"), do {
                my $x = sprintf("  %-20s  ", $2 // " ");
                $x =~ s/[\[\]]/ $& =~ m!\[! ? BRIGHT_BLACK . $& : $& . BRIGHT_YELLOW /ge;
                $x = BRIGHT_YELLOW . $x . RESET;
            },
            colored($3, "bold blue"),
            "\n";
        }
        ' $RIG_RC/rc.sh
    else
        grep -e "^#" $RIG_RC/rc.sh | tail -n +2 | sed "s/^#[ \\t]\?//"
    fi
    echo
}


# run code - показать код bash и выполнить его
run() {
    echo "$*"
    eval "$*"
    local c="$?"
    if [ "$c" != 0 ]; then echo "Завершение команды: $c. Выходим"; fi
}

# locallib - указать локальную директорию для пакетов perl
alias locallib='cpanm --local-lib=~/.local/lib/perl5 local::lib && eval $(perl -I ~/.local/lib/perl5/lib/perl5/ -Mlocal::lib)'

#@category git

# gitconf - конфигурирует git
gitconf() {
    git config --global pull.rebase false   # rebase
    git config --global pull.ff only       # fast-forward only
}

# git_diff - при изменениях в репозитории предлагает пользователю варианты действий с ними
git_diff() {
    local m=`git status -s`
    if [ "$m" != "" ]; then
        git status -s
        PS3="Ваш выбор:"
        select i in Комитим Ресетим diff stash Пропускаем Отмена
        do
            case $i in
                Комитим) read -p "Введите комментарий: " a; commit "$a"; break;;
                Ресетим) run git reset --hard HEAD; break;;
                diff) git diff;;
                stash) run git stash; break;;
                Пропускаем) echo "Пропущено"; break;;
                Отмена) return 1;;
            esac
        done
    fi
    return 0
}

# desc - печатает описание текущего бранча
alias desc='git config branch.`branch`.description'

# sta - показать сокращённый git-статус
alias sta="git status -s"

# sta1 - показать git-статус
alias sta1="git status"

# reset - удалить изменения в файлах
alias reset='git reset --hard HEAD'

# gl - лог гита со списками файлов
alias gl='git log --name-only --graph'


# gitgrep [options] regexp - поиск теста во всех репозиториях
gitgrep() {
    git grep $* $(git rev-list --all)
}

# githist file - история изменения файла
githist() {
    git log -p -- "$1"
}

# bdiff [branch] - сравнение двух бранчей. Выполните installrig или установите kompare
bdiff() {
    git diff ${GIT_NEW_FROM:-master}...${1:-`branch`} | kompare -
}

# pushinit - комитит и пушит в первый раз
alias pushinit='git add . && git commit -am init && git push --set-upstream origin master'


# new branch - создаёт ветку
new() {
    if ! git_diff; then return; fi
    run git checkout ${GIT_NEW_FROM:-master}
    run git pull origin ${GIT_NEW_FROM:-master} --no-edit
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
    local status=$?
    local b=`branch`
    if [ "$b" != "" ]; then echo -n " $b"; fi
    if [ "$status" != 0 ]; then echo -n " 😡"; fi
    #echo " 😱😈🙀😾"
}

# c0 [branch] - переключение на ветку. Если не указана - на предыдущий. Алиас с0 - c русская
alias с0=c0
c0() {
    local branch
    branch="$1"
    if [ "$branch" == "" ]; then branch=$C0; fi

    if git_diff; then
        C0=`branch`
        git checkout $branch
        echo $branch `desc`
    fi
}


# commit - комитит. Если нечего комитить - ничего не делает
commit() {
    if [ "`sta`" != "" ]; then
        sta
        if [ "$PRECOMMIT" != "" ]; then . $PRECOMMIT; fi
        run git add .
        local x
        if [ "$1" == "" ]; then x="`desc`"; else x="$1"; fi
        x="`echo \"$x\" | sed \"s/'/\\\\'/g\"`"
        run "git commit -am '`branch` $x'" || return $?
    fi
}

# upd - обновить ветку с мастера
upd() {
    run "git merge  --no-edit --no-ff origin/${GIT_NEW_FROM:-${1:-master}}"
}

# push [comment] - делает комит текущей ветки
push() {
    local branch
    if [ -x "act" ]; then ./act meta || return 1; fi
    branch=`branch`
    if [ "$1" == 1 ]; then commit "`desc`"; else commit "$1"; fi || return $?
    run "git pull origin $branch --no-edit || git merge --no-ff --no-edit origin/$branch" || return $?
    run "git push origin $branch" || return $?
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

    run "git pull origin $branch --no-edit || git merge --no-ff --no-edit origin/$branch"
    if [ -x "act" ]; then ./act meta || return 1; fi
}

# merge - мержит текущую ветку с мастером и удаляет её
merge() {
    local b="`branch`"
    echo "=== merge $b ==="
    push "${1:-`desc`}"
    run "c0 master"
    run "git merge --no-ff --no-edit $b"
    run "push 'Слияние $b \"`desc`\"'"
    if [ "$1" == "1" ]; then
        echo "=== Удаление $b ==="
        run "git push origin :$b"
        run "git branch -D $b"
    fi
}

# indev - добавляет текущую ветку в ветку dev
indev() {
    local x=dev
    c0 $x                                     \
    && run "git pull origin $x --no-edit"     \
    && run "git merge --no-edit --no-ff $C0"  \
    && run "git push origin $x"               \
    && c0
}

#@category Релизы

# release - релиз текущего perl-dist
release() {
    if [ "$PERL_LOCAL_LIB_ROOT" == "" ]; then
        cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    fi
    liveman -fc && minil release
}

# release1 [desc] - Делается на проде. pull и устанавливает тег
release1() {
    local ver="`date '+%F %T'`"
    commit "Релиз версии $ver"
    if [ "$1" == "" ]; then
        git tag -a "$ver"
    else
        git tag -a "$ver" -m "$1"
    fi
    git push origin --tags
}

# release2 version-message - ставит тег и меняет версию в README.md
release2() {
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

# github [name] - клонировать с github мой проект или перейти на github
github() {
    if [ "$1" == "" ]; then
        opera `git remote get-url origin | sed 's/^git@//' | sed 's/.git$//' | sed 's/:/\//'`
    else
        git clone git@github.com:darviarush/$1.git
    fi
}

# install_pip - установить pip с инета
alias install_pip='curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && python3 /tmp/get-pip.py'


#@category Переходы

# cda - cd to astrobook
alias cda='cd ~/__/astrobook'

# cdl - cd to le-yoga
alias cdy='cd ~/__/le-yoga'


# cdl - cd to @lib
alias cdl='cd ~/__/@lib'

# cdla - cd to perl-aion
alias cdla='cd ~/__/@lib/perl-aion'

# cdlact - cd to perl-aion-action
alias='cdlact=cd ~/__/@lib/perl-aion-action'

# cdlc - cd to perl-aion-carp
alias 'cdlc=cd ~/__/@lib/perl-aion-carp'

# cdlf - cd to perl-aion-format
alias 'cdlf=cd ~/__/@lib/perl-aion-format'

# cdlfs - cd to perl-aion-fs
alias 'cdlfs=cd ~/__/@lib/perl-aion-fs'

# cdlq - cd to perl-aion-query
alias 'cdlq=cd ~/__/@lib/perl-aion-query'

# cdlr - cd to perl-aion-run
alias 'cdlr=cd ~/__/@lib/perl-aion-run'

# cdls - cd to perl-aion-sige
alias 'cdls=cd ~/__/@lib/perl-aion-sige'

# cdlsp - cd to perl-aion-spirit
alias 'cdlsp=cd ~/__/@lib/perl-aion-spirit'

# cdlsu - cd to perl-aion-surf
alias 'cdlsu=cd ~/__/@lib/perl-aion-surf'

# cdlt - cd to perl-aion-telemetry
alias 'cdlt=cd ~/__/@lib/perl-aion-telemetry'

# cdlv - cd to perl-aion-view
alias 'cdlv=cd ~/__/@lib/perl-aion-view'

# cde - cd to erswitcher
alias cde='cd ~/__/erswitcher'

# cdn - cd to ninja
alias cdn='cd ~/__/ninja'

# cdnx - cd to mx-basic
alias cdmx='cd ~/__/mx-basic'

# cdth - cd to ethereal-theory
alias cdth='cd ~/__/ethereal-theory'

# cdfr - cd to rubin-forms
alias cdrf='cd /mnt/ext/__/rubin-forms'

# cds - cd to golang-perl-storable
alias cds='cd ~/__/golang-perl-storable'

# cdt - cd to test directory
alias cdt='cd ~/__1/'

# cdr - cd to restoclub directory
alias cdr='cd /home/Project/restoclub-2022'

# cdcrm - cd to crm directory
alias cdcrm='cd /home/Project/crm-2020'

# cdga - cd to ga directory
alias cdga='cd /home/Project/google.analytics.microservice'

# cdmb - cd to monitoring_bot directory
alias cdmb='cd /home/Project/monitoring_bot'

# cdapi - cd to api directory
alias cdapi='cd /home/Project/api.restoclub.ru'

# cdv3 - cd to node v3
alias cdv3='cd /home/Project/node-ssr-v3/client'

# cdrig - cd to rig
alias cdrig='cd $RIG_RC'


#@category Утилиты

# npp - запустить notepad++ в новом окне
alias npp='~/.wine/drive_c/Program\ Files/Notepad++/notepad++.exe -multiInst &> /dev/null &'

# brig - регулировка яркости экрана
brig() {
    local b
    for i in /sys/class/backlight/*
    do
        echo $i
        echo "Яркость 0-`cat $i/max_brightness`: `cat $i/brightness`"
        echo -n "Введите новую: "

        read b
        sudo sh -c "echo $b > $i/brightness"
    done
}

# packagecheck - Проверяет пакеты на ошибки
alias packagecheck='sudo paccheck --files --file-properties --db-files --quiet --sha256sum'

# sysreinstall - Переинсталлить все пакеты
alias sysreinstall='pacman -Qqn | pacman -S -'

# ports - Посмотреть порты через ss
alias ports='sudo ss -tlpn'

# ports1 - Посмотреть порты через netstat
alias ports1='sudo netstat -tlpn'

# scpp u@h:/file file - scp с прогрессом
scpp() {
    rsync -r -v --progress -e ssh "$1" "$2"
}

# vg - перейти в каталог ~/_vg и запустить vagrant
vg() {
    pushd ~/_vg
    vagrant $*
    popd
}

# portal - подключение по ssh для нестандартного порта
alias portal='ssh -p 6022 '

# defopt - установить опции окружения по умолчанию
defopt() {
    xdg-settings set default-web-browser opera.desktop
}

# installrig - инсталлирует самое необходимое
installrig() {
    pamac install aspell hspell libvoikko kompare
}


# drm container - остановить и удалить контейнер
drm() {
    docker stop -t 0 $1
    docker rm $1
}

# bashing - перечитать .bashrc в терминале
alias bashing='. ~/.bashrc'

# bashed - редактировать .bashrc и перечитать
alias bashed='mcedit ~/.bashrc; . ~/.bashrc'

#@category Файловые сниппеты

# mk snippet name [1] - копирует сниппет с подстановками в текущий каталог. [1] - директорию сделать flat
alias mk='$RIG_RC/bin/mk.sh'

# mkdist pkg - создать дистрибутив библиотеки perl
mkdist() {
    local pkg=$1
    local name=`echo -n $1 | sed 's/::/-/g'`
    local path=lib/`echo -n $1 | sed 's/::/\//g'`
    local dir=perl-${name,,}

    local wf=.github/workflows
    mkdir -p $dir/$wf || return
    cp $RIG_RC/snippet/perl-dist/$wf/test.yml $dir/$wf/ || return

    local mdpath=$path.md
    local pmpath=$path.pm
    local var=`echo -n $1 | sed 's/::/_/g'`

    for i in $RIG_RC/snippet/perl-dist/* $RIG_RC/snippet/perl-dist/.gitignore; do
	echo $i `basename $i`
	year=`date +%Y` var=${var,,} dir=$dir pkg=$pkg name=$name mdpath=$mdpath pmpath=$pmpath perl -np -e 's/\{\{(\w+)\}\}/$ENV{$1}/g' $i >  $dir/`basename $i`
    done

    mkdir -p $dir/`dirname $path` || return
    cp $dir/README.md $dir/$mdpath
    mv $dir/MOD.pm $dir/$pmpath

    cd $dir
    git init
    git remote add origin git@github.com:darviarush/$dir.git

    opera "https://github.com/new?name=$dir&description=$pkg%20is%20" &> /dev/null
}

#@category python - тесты и создание пакетов

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

#@category perl

# cov - тестирование perl-проектов с cover
cov() {
    cover -delete
    #PERL5OPT="$PERL5OPT -MDevel::Cover" prove -Ilib
    yath test -j4 --cover && cover -report html_basic || return 1
    if [ "$1" == "-O" ]; then xdg-open cover_db/coverage.html
    elif [ "$1" == "-o" ]; then opera cover_db/coverage.html
    fi
}


# pmuninstall - удаляет perl-модуль
alias pmuninstall='sudo cpanm --uninstall'


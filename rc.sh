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
    local c="$?"
    if [ "$c" != 0 ]; then echo "Завершение команды: $c. Выходим"; fi
}

# locallib - указать локальную директорию для пакетов perl
alias locallib='cpanm --local-lib=~/.local/lib/perl5 local::lib && eval $(perl -I ~/.local/lib/perl5/lib/perl5/ -Mlocal::lib)'

# git_diff - при изменениях в репозитории предлагает пользователю варианты действий с ними
git_diff() {
    local m=`git status -s`
    if [ "$m" != "" ]; then
        git status -s
        PS3="Ваш выбор:"
        select i in Комитим Ресетим stash Пропускаем Отмена
        do
            case $i in
                Комитим) read -p "Введите комментарий: " a; commit "$a"; break;;
                Ресетим) run git reset --hard HEAD; break;;
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


# new branch - создаёт ветку
new() {
    if ! git_diff; then return; fi
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
    local status=$?
    local b=`branch`
    if [ "$b" != "" ]; then echo -n " $b"; fi
    if [ "$status" != 0 ]; then echo -n " 😡"; fi
    #echo " 😱😈🙀😾"
}

# c0 branch - переключение на ветку
c0() {
    if git_diff; then
        git checkout $1
    fi
}

# bdiff [branch] - сравнение двух бранчей. Выполните installrig или установите kompare
bdiff() {
    git diff master...${1:-`branch`} | kompare -
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
    run "git merge origin/${1:-master} --no-edit --no-ff"
}

# push [comment] - делает комит текущей ветки
push() {
    branch=`branch`
    if [ "$1" == 1 ]; then commit "`desc`"; else commit "$1"; fi || return $?
    run "git pull origin $branch --no-edit || git merge --no-ff origin/$branch" || return $?
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

    run "git pull origin $branch --no-edit || git merge --no-ff origin/$branch"
}

# merge - мержит текущую ветку с мастером и удаляет её
merge() {
    local b="`branch`"
    echo "=== merge $b ==="
	push "${1:-`desc`}"
    run "c0 master"
    run "git merge --no-ff $b"
    run "push 'Слияние $b \"`desc`\"'"
    if [ "$1" == "1" ]; then
        echo "=== Удаление $b ==="
        run "git push origin :$b"
        run "git branch -D $b"
    fi
}


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

# cov - тестирование perl-проектов с cover
cov() {
    cover -delete
    PERL5OPT="$PERL5OPT -MDevel::Cover" prove -Ilib
    cover -report html_basic
    if [ "$1" == "-O" ]; then xdg-open cover_db/coverage.html
    elif [ "$1" == "-o" ]; then opera cover_db/coverage.html
    fi
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

# installrig -         инсталлирует самое необходимое
installrig() {
    pamac install aspell hspell libvoikko kompare
}

# cmd - Команда symphony в докере
alias cmd='make localhost-cmd l="run --rm service-php-cli app/console"'

# migsta - Статус миграций доктрины
alias migsta='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:status --show-versions"'

# miggen - Новая миграция доктрины
alias miggen='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:generate"'

# migdiff - Отличия в миграции доктрины
alias migdiff='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:diff"'

# migup1 - Накатить миграции доктрины по одной
alias migup1='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:migrate --up"'

# migx version [--up|--down]  - Накатить конкретную миграцию доктрины (20180601193057)
migx() {
    make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:execute $*"
}

# migup - Накатить миграции доктрины
alias migup='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:migratee"'

# migdown - Откатить миграции доктрины
alias migdown='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:migrate prev"'

# migtab table - Создать entity по таблице
migtab() {
    make localhost-cmd l="run --rm service-php-cli app/console doctrine:make:entity"
}

# drm container - Остановить и удалить контейнер
drm() {
    docker stop -t 0 $1
    docker rm $1
}

# front - Пересобрать фронт
front() {
    make localhost-node-cli l="bash -c 'cd front; ./node_modules/.bin/gulp buildDev'"
}

# frontnpm - Переустановить npm i
frontnpm() {
    make localhost-node-cli l="bash -c 'cd front; npm i'"
}

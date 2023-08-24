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
alias fn='pushd $RIG_RC; mcedit rc.sh; . rc.sh; push fn; popd'

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


# new branch - создаёт ветку
new() {
    if ! git_diff; then return; fi
    run git checkout master
    run git pull origin master --no-edit
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

# release [desc] - Делается на проде. pull и устанавливает тег
release() {
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

# github name - клонировать с github мой проект
github() {
    git clone git@github.com:darviarush/$1.git
}

# install_pip - установить pip с инета
alias install_pip='curl https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py && python3 /tmp/get-pip.py'


# cda - cd to astrobook
alias cda='cd ~/__/astrobook'

# cdl - cd to @lib
alias cdl='cd ~/__/@lib'

# cdla - cd to perl-aion
alias cdla='cd ~/__/@lib/perl-aion'

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
alias cdv3='cd /home/Project/node-ssr-v3'

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

# ports - Посмотреть порты через ss
alias ports='sudo ss -tlpn'

# ports1 - Посмотреть порты через netstat
alias ports1='sudo netstat -tlpn'

# vg - перейти в каталог ~/_vg и запустить vagrant
vg() {
    pushd ~/_vg
    vagrant $*
    popd
}

# mk snippet name [1] - копирует сниппет с подстановками в текущий каталог. [1] - директорию сделать flat
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
    #PERL5OPT="$PERL5OPT -MDevel::Cover" prove -Ilib
    yath test -j4 --cover && cover -report html_basic || return 1
    if [ "$1" == "-O" ]; then xdg-open cover_db/coverage.html
    elif [ "$1" == "-o" ]; then opera cover_db/coverage.html
    fi
}

# pmuninstall - удаляет perl-модуль
alias pmuninstall='sudo cpanm --uninstall'

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


# drm container - Остановить и удалить контейнер
drm() {
    docker stop -t 0 $1
    docker rm $1
}


#### Симфония

# cmd - Команда symphony в докере
cmd() {
    if [ -e api ]; then
        docker-compose run --rm api-php-cli bin/console $*
    else
        make localhost-cmd l="run --rm service-php-cli app/console $*"
    fi
}

# cmdx - Команда в докере
cmdx() {
    if [ -e api -o -e ../api ]; then
        docker-compose run --rm api-php-cli $*
    else
        make localhost-cmd l="run --rm service-php-cli $*"
    fi
}

# ccache - Очистка кеша
alias ccache='make localhost-cmd l="run --rm service-php-cli app/console restoclub:core:clear-cache"'

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
# make dc-cmd l="run --rm service-php-cli-1 app/console doctrine:migrations:execute $*"

# migup - Накатить миграции доктрины
alias migup='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:migrate"'

# migdown - Откатить миграции доктрины
alias migdown='make localhost-cmd l="run --rm service-php-cli app/console doctrine:migrations:migrate prev"'

# migtab table - Создать entity по таблице
migtab() {
    make localhost-cmd l="run --rm service-php-cli app/console doctrine:make:entity"
}

# mkmig - создать миграцию на основе текущего времени и открыть её в phpstorm-е
mkmig() {
    local path=/home/Project/restoclub-2022/migrations/`date +%Y`/`date +%m`
    mkdir -p $path
    pushd $path
    mk mig _ 1
    popd

    /usr/bin/env phpstorm --line 23 "${path}/Version$(date +%Y%m%d%H%M%S).php"
}

# mkbundle Name - создать бандл и открыть его в phpstorm-е
mkbundle() {
    local path=/home/Project/restoclub-2022/src
    mkdir -p $path
    pushd $path
    mk bundle ${1,,}
    mv ${1,,}/* ${1}Bundle
    rmdir ${1,,}
    popd

    /usr/bin/env phpstorm --line 23 "${path}/${1}Bundle/Entity/$1.php"
}

# mkentity bundle entity - создать энтити в бандле и открыть его в phpstorm-е
mkentity() {
    local path=/home/Project/restoclub-2022/src/${1}Bundle

    if [ ! -e $path ]; then echo "Нет $path"; return 0; fi
    if [ "" == "$2" ]; then echo "Нет 2-го параметра - имени Entity"; return 0; fi

    path=$path/Entity
    mkdir -p $path

    pushd $path
    mk entity $2
    popd

    /usr/bin/env phpstorm --line 23 "${path}/$2.php"
}


# front - Пересобрать фронт
front() {
    make localhost-node-cli l="bash -c 'cd front; ./node_modules/.bin/gulp buildDev'"
}

# frontjs - Пересобрать только js
frontjs() {
    make localhost-node-cli l="bash -c 'cd front; ./node_modules/.bin/gulp buildJsDev'"
}

# frontnpm - Переустановить npm i
frontnpm() {
    make localhost-node-cli l="bash -c 'cd front; npm i'"
}


# startfix - временный баг
startfix() {
    sudo chown dart:dart -R /tmp/openapi web/uploads &> /dev/null
    rm -fr web/uploads
    mkdir -p web/uploads
    chmod 777 web/uploads

    mkdir -p /tmp/cache/nginx
    chmod 777 /tmp/cache/nginx

    mkdir -p /tmp/log/nginx
    echo > /tmp/log/nginx/dev-cache_pages.log
    chmod 777 /tmp/log/nginx
    chmod 777 /tmp/log/nginx/dev-cache_pages.log
}

# starter - запускает проект
starter() {
    cdcrm
    make dc-up-d
    cdr
    #startfix
    make sf-def-parameters env="localhost"
    make localhost-up l=-d
    xdg-open https://restoclub.localhost
}

# pushdev [комментарий] - push и indev
pushdev() {
    push "$1"
    indev
}

# routers - выборка по роутам symphony
alias routers='cmd debug:route | grep '

# ga - генерирует документацию по openapi
alias ga='cmd rc:api:gen-docs'

# task - открывает задачу текущей ветки
alias task='xdg-open https://restoclub.myjetbrains.com/youtrack/issue/`branch`'

# mksymfeature category/name - создать тест symphony и открыть его в phpstorm-е
mksymfeature() {
    local file=`basename $1`
    local dir=`dirname $1`

    local path=/home/Project/restoclub-2022/tests/symfony/$dir
    mkdir -p $path
    pushd $path
    mk symfeature $file
    popd

    /usr/bin/env phpstorm --line 4 "${path}/$file.feature"
}

# mkapifeature путь/имя - создать тест api и открыть его в phpstorm-е
mkapifeature() {
    local file=`basename $1`
    local dir=`dirname $1`

    local path=/home/Project/restoclub-2022/tests/api/$dir
    mkdir -p $path
    pushd $path
    mk apifeature $file
    popd

    /usr/bin/env phpstorm --line 4 "${path}/$file.feature"
}

# fromtest - переключиться на локальную базу с тестовой
alias fromtest='make sf-def-parameters env=localhost && ccache'

# features - подготавливает тесты
features() {
    chmod -R 0777 ./bin/
    make sf-clear-cache env="test"

    make testing-clear
    make testing-create-dirs
    #make testing-create-db # (если тестовой базы нет testing-create-db)
    make testing-migrate-db

    make sf-def-parameters env=localhost
}

# feature path - запустить тест
feature() {
    make testing-codecept-sf-path path=$1.feature
    make sf-def-parameters env=localhost
}

# symtst - запускает тесты для релиза
symtst() {
    features

    make testing-php-lint # (проверяет синтаксис)
    make testing-forgotten-debug-check # (проверя)
    make testing-codecept-sf # (запуск всех симфони тестов)

    make sf-def-parameters env=localhost
    rm -fr var/cache/*
}

# pr - создаёт pull-request для указанной ветки
pr() {
    opera "https://bitbucket.org/restonet/restoclub-2019/pull-requests/new?source=$(branch )&t=1"
}

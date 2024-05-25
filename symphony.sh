#!/bin/bash

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


frontcrm() {
    make api-old-front-build-dev
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

# frontadmin - Пересобрать фронт админки
frontadmin() {
    make localhost-node-cli l="bash -c 'cd front-admin; node scripts/build.js development'"
}

# frontcrm - Пересобрать фронт crm
alias frontcrm='make api-old-front-build-dev'


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

# pr - создаёт pull-request для текущей ветки
pr() {
    opera "https://bitbucket.org/restonet/restoclub-2019/pull-requests/new?source=$(branch )&t=1&dest=release_candidate" &> /dev/null
}

# pullprod - пулл на прод
alias pullprod='c0 master && pull && make login-2rrc-registry release--prod-monada'

# pulldev - пулл на дев
alias pullprod='indev && c0 dev && make login-2rrc-registry release--dev-monada'

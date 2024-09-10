# NAME

`rig` — набор скриптов bash для разработки с помощью git и файловых сниппетов

# SPECIFICATION

```sh

$ new 'AS-2 Создать скелет проекта'
$ mk site supersite 1
$ push 'Скелет проекта создан'
$ merge 

```

# DESCRIPTION

Список алиасов и функций:

* `fn` — отредактировать `rig/rc.sh` и внести его в bash.
* `-help` — показать список целей.
* `run` __code...__ — показать код bash и выполнить его.
* `desc` — печатает описание текущего бранча.
* `new` __branch__ — создаёт ветку.
* `branch` — показать текущую ветку.
* `branch_prompt` — показать ветку красной и с отступом в пробел, если есть.
* `c0` __branch__ — переключение на ветку.
* `bdiff` — сравнение двух бранчей. Выполните **installrig** или установите **kompare**.
* `commit`  — комитит. Если нечего комитить — ничего не делает.
* `upd` — обновить ветку с мастера.
* `push` __[comment]__ — делает комит текущей ветки.
* `pull` — пулл текущей ветки.
* `merge` — мержит текущую ветку с мастером и удаляет её.
* `sta` — показать сокращённый git—статус.
* `sta1` — показать git—статус.
* `reset` — удалить изменения в файлах.
* `release` __version—message__ — ставит тег и меняет версию в README.md.
* `version` — версия из README.md текущего проекта.
* `github` __name__ — клонировать с github мой проект.
* `install_pip` — установить pip с инета.
* `cda` — cd to astrobook.
* `cde` — cd to erswitcher.
* `cdn` — cd to ninja.
* `cds` — cd to sua—basic.
* `cdth` — cd to ethereal—theory.
* `npp` — запустить **notepad++** в новом окне.
* `vg` __args...__ — перейти в каталог ~/_vg и запустить vagrant.
* `mk` __snippet__ __name__ __[1]__ — копирует сниппет с подстановками в текущий каталог. 1 — не в каталоге.
* `py_test` — тестирует пакет питон в текущей папке с покрытием.
* `py_upload` — загружает текущий репозиторий питон как пакет в **pypi**.
* `py_upload_only` — загружает текущий репозиторий питон как пакет в **pypi** не тестируя его и не пуша.
* `py_init` — настраивает консоль на работу с pyenv.
* `cov` — тестирование perl—проектов с cover (покрытием).
* `portal` — подключение по ssh для нестандартного порта.
* `defopt` — установить опции окружения по умолчанию.
* `gitconf` — конфигурирует git.
* `installrig` — инсталлирует самое необходимое (aspell, hspell, libvoikko, kompare).

Список сниппетов: 

* c
* cc
* m
* perl-dist
* python-dist
* site

# DEPENDENCIES

* bash
* git
* kompare [OPTIONAL]

# INSTALL

```sh
$ git clone https://github.com/darviarush/rig.git
$ cd rig
$ . ./rc.sh startup
```

# AUTHOR

_Yaroslav O. Kosmina_ <darviarush@mail.ru>.

# LICENSE

⚖ **GPLv3**

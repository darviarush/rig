#!/bin/bash

# Может измениться, см. https://upload.pypi.org/

pkg=`basename $(pwd )`
pypkg=`echo -n $pkg | sed 's/-/_/g' | sed 's/python_//'`

echo
echo step 0 - удаление ненужных файлов
rm -fr build dist *.egg_info htmlcov
#py_test
#push dist

#echo
#echo step 1
#python3 -m pip install --user --upgrade setuptools wheel

#echo
#echo step 2
#python3 setup.py sdist bdist_wheel

#echo
#echo step 3
#python3 -m pip install --user --upgrade twine

echo
echo step 1 - билд
python3 -m build

echo
echo step 2 - загрузка на тестовый сервер
python3 -m twine upload --repository testpypi dist/*

echo
echo step 3 - установка с тестового сервера
python3 -m pip install --user --index-url https://test.pypi.org/simple/ --no-deps $pkg

echo
echo step 4 - удаление пакета
pip3 uninstall --user $pypkg

echo
echo step 5 - загрузка на сервер
twine upload dist/*

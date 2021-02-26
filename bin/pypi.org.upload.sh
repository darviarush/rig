#!/bin/sh

pkg=$1
pypkg=`echo -n $pkg | sed 's/-/_/g'`

echo
echo step 1
python3 -m pip install --user --upgrade setuptools wheel

echo
echo step 2
python3 setup.py sdist bdist_wheel

echo
echo step 3
python3 -m pip install --user --upgrade twine

echo
echo step 4
python3 -m twine upload --repository testpypi dist/*

echo
echo step 5
python3 -m pip install --index-url https://test.pypi.org/simple/ --no-deps $pkg

echo
echo step 6
pip3 uninstall $pypkg

echo
echo step 7
twine upload dist/*

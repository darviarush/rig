#!/bin/bash

# Устанавливает libre-office вместе со всеми словарями для проверки правописания русского и английского языков

sudo pacman --noconfirm -S ttf-dejavu \
	libreoffice-fresh libreoffice-fresh-ru \
	hunspell  hunspell-en_us \
	hyphen hyphen-en \
	libmythes mythes-en \
	|| exit

yay -S hunspell-ru-aot-ieyo --answerclean All --answerdiff N || exit
yay -S hyphen-ru --answerclean All --answerdiff N || exit
yay -S mythes-ru --answerclean All --answerdiff N || exit

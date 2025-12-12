#!/bin/sh

if [ -f "$HOME/.note.lock" ] && (kill -s 0 $(cat ~/.note.lock));  then
    i3-msg '[title="notebook"] focus'
    exit 0
fi
clsw
touch ~/.note.lock
echo $PPID > ~/.note.lock
echo -ne "\033]0;notebook\007"
vim ~/.note.txt +startinsert
rm ~/.note.lock


#!/bin/sh

if [ ! -f "$HOME/.note.lock" ] || ! (kill -s 0 $(cat ~/.note.lock));  then
    clsw
    touch ~/.note.lock
    echo $PPID > ~/.note.lock
    vim ~/.note.txt +startinsert
    rm ~/.note.lock
fi


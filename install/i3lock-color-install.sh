#!/bin/sh

git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color

cd /tmp/i3lock-color

./build.sh

./install-i3lock-color.sh

cd -

rm -rf /tmp/i3lock-color

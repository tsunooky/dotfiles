#!/bin/sh

sudo sed -i '/ILoveCandy/d' /etc/pacman.conf

sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

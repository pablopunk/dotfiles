#!/bin/bash

brew_install unison
mkdir -p ~/.dotfiles/.unison/Library/Preferences
unison preferences $HOME $HOME/.dotfiles/.unison

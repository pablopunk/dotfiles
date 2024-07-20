#!/bin/bash

brew_install unison
unison preferences $HOME $HOME/.dotfiles/.unison -auto

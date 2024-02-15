#!/bin/bash

nvim --headless "+Lazy! install" "+Lazy! update" "+Lazy! clean" +qa > /dev/null 2>&1


#!/bin/bash

./link.sh
./bootstrap.sh

echo "bash install.sh" > .git/hooks/post-merge
chmod +x .git/hooks/post-merge

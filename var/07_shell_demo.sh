#!/bin/bash

echo "All variables in the current shell: $@"
echo "All variables in the current shell: $*"
echo "Script name: $0"
echo "current working directory: $PWD"
echo "who running the script: $USER"
echo "Home directory: $HOME"
echo "PID of the script: $$"
sleep 30 &
echo "PID of the last background process: $!"
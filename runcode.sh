#!/bin/bash

dd=`date "+%Y-%m-%d-%H-%M-%S"`

mkdir -p data/$dd
cp pressure_GAUSSIAN.f90 makefile data/$dd
cd data/$dd
make -i clean
make main
tmux new-session -d ./mainex

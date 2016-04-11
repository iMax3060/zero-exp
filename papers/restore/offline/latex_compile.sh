#!/bin/bash

PREFIX=$1

gnuplot -e 'prefix="'$PREFIX'"' gnuplot/bandwidth_all.gp
pdflatex bandwidth_"$PREFIX" 
cp bandwidth_"$PREFIX".pdf ~/work/papers/InstantRestore/img/

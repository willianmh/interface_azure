#!/bin/bash
set -x
mkdir -p BRAMS
cp brams-5.3-src.tgz BRAMS

cd BRAMS
tar -zxvf brams-5.3-src.tgz
cd build
./configure -program-prefix=BRAMS -prefix=/home/username -enable-jules -with-chem=RELACS_TUV -with-aer=SIMPLE -with-fpcomp=/opt/mpich3/bin/mpif90 -with-cpcomp=/opt/mpich3/bin/mpicc -with-fcomp=gfortran -with-ccomp=gcc
make; sudo make install

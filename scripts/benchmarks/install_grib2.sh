#!/bin/bash

wget ftp://ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/wgrib2.tgz
rm -r grib2
tar -xzvf wgrib2.tgz
cd grib2
export CC=gcc
export FC=gfortran
make
make lib

export PATH=$PATH:~/grib2/wgrib2

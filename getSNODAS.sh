#! /bin/bash
# 2017-07-10
# E.A. Burakowski
# Retrieves Nov-Apr (2004-2017) NOHRSC SNODAS .tar from National Snow and Ice Data Center (NSDIC)
# server (sidads.colorado.edu)
 

    for months in "11_Nov" "12_Dec" "01_Jan" "02_Feb" "03_Mar" "04_Apr"
    do
	  wget ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/masked/{2010..2017}/"$months"/*.tar
    done

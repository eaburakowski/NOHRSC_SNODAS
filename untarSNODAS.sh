#! /bin/bash

# Stop of get any simple error
 set -e

# process NOHRSC SNODAS files
# (1) untar
# (2) unzip
# (3) copy .HDR to .hdr
# (4) move .dat to variable specific dirs
	# PRLQ = liquid precipitation
	# PRSL = solid precipitation
	# SWEM = snow water equivalent, in meters
	# SNWZ = snow depth
	# SNWT = snowpack temperature
	# SUBB = sublimation from blowing snow
	# SUBS = sublimation from snow pack

# Move to data dir
 cd download_data

# Loop over SNODAS tar files
 for file in *.tar; 
 do
 
 # (1) untar
 tar -xvf $file

 # (2) unzip
 gunzip -f *.gz

 # (3) move all .Hdr files to another dir (messes up gdal command)
 mkdir -p Hdr
 mv *.Hdr Hdr/.
	
	# List the .dat files from the unzipped folder
	FILES=*.dat

	# (4) loop over .dat files and move to specific dirs
	for datfiles in $FILES
	do
		case $datfiles in
			*1025SlL00*)
                        mkdir -p PRLQ 
			mv $datfiles PRLQ/.
			;;
			*1025SlL01*) 
                        mkdir -p PRSL
			mv $datfiles PRSL/.
			;;
			*1034*) 
                        mkdir -p SWEM
			mv $datfiles SWEM/.
			;;
			*1036*) 
                        mkdir -p SNWZ
			mv $datfiles SNWZ/.
			;;
			*1038*) 
                        mkdir -p SNWT
			mv $datfiles SNWT/.
			;;
			*1039*) 
                        mkdir -p SUBB
			mv $datfiles SUBB/.
			;;
			*1044*) 
                        mkdir -p SNWM
			mv $datfiles SNWM/.
			;;
			*1050*) 
                        mkdir -p SUBS
			mv $datfiles SUBS/.
			;;
		esac
	done
done
		

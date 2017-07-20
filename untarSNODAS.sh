#! /bin/bash

# process NOHRSC SNODAS files
# (1) untar
# (2) unzip
# (3) copy .HDR to .hdr
# (4) move .dat to variable specific dirs

# Loop over SNODAS tar files
 for file in *.tar; 
 do
 
 # (1) untar
 tar -xvf $file

 # (2) unzip
 gunzip *.gz

 # (3) move all .Hdr files to another dir (messes up gdal command)
 mv *.Hdr Hdr/.
	
	# List the .dat files from the unzipped folder
	FILES=*.dat

	# (4) loop over .dat files and move to specific dirs
	for datfiles in $FILES
	do
		case $datfiles in
			*1025SlL00*) 
			mv $datfiles PRLQ/.
			;;
			*1025SlL01*) 
			mv $datfiles PRSL/.
			;;
			*1034*) 
			mv $datfiles SWEM/.
			;;
			*1036*) 
			mv $datfiles SNWZ/.
			;;
			*1038*) 
			mv $datfiles SNWT/.
			;;
			*1039*) 
			mv $datfiles SUBB/.
			;;
			*1044*) 
			mv $datfiles SNWM/.
			;;
			*1050*) 
			mv $datfiles SUBS/.
			;;
		esac
	done
done
		

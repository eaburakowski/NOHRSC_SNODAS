#! /bin/bash

# Stop of get any simple error
 set -e

# EA Burakowski 
# 2017-07-17

# Process NOHRSC SNODAS daily .dat files, convert to .nc following recommended procedures from NSIDC: https://nsidc.org/support/how/how-do-i-convert-snodas-binary-files-geotiff-or-netcdf


# (1) Create generic .hdr file:
	# ENVI
	# samples = 6935
	# lines   = 3351
	# bands   = 1
	# header offset = 0
	# file type = ENVI Standard
	# data type = 2
	# interleave = bsq
	# byte order = 1
	# map info = {Geographic, 0, 0, -124.729583333331703, ...	
	# 52.871249516804028, 0.00833333333, 0.00833333333} 
# (2) gdal_translate: convert .dat (binary) to .nc
# (3) ncrename: change variable name from gdal band1 to appropriate variable name
# (4) ncatted: add long_name to variable
# (5) ncatted: add units to variable


# Assumes .dat files are stored in separate directories for each variable.  
# Sub-directory names are 4-letter abbreviations. Feel free to change, however
# they should be consistent with untarSNODAS.sh
# Options include: 
	# PRLQ - liquid precip
	# PRSL - solid precip
	# SNWM - snow melt (from base of snowpack)
	# SNWT - snowpack integrated temperature
	# SNWZ - snow depth
	# SUBB - sublimation from blowing snow
	# SUBS - sublimation from snow pack
	# SWEM - snow water equivalent
	# convert .dat (binary) to .nc (netCDF)
 
##############################################################################
#
#	Main Code
#
##############################################################################
 
 # Make sure the SNODAS_DATA_DIR environment variable is set
 if [ -z "$SNODAS_DATA_DIR" ]; then
    echo "Need to set SNODAS_DATA_DIR"
    exit 1
 fi

 # Flag if using masked or unmasked SNODAS extent
 masked=false 
 
 # Flag to subset netcdf files (removes original one!)   
 subset=true 

 # Define sub Region Of Interest (ROI)
 # CRHO - SnowCast
 lon_min=-116.645
 lon_max=-114.769166666667
 lat_min=50.66
 lat_max=51.7933333333333

 # Define directory with variable subdirs of dat files
 cd $SNODAS_DATA_DIR
 
 # Define path to generic .hdr
 genhdr=$SNODAS_DATA_DIR"/generic.hdr"
 
 # Define out directory for .nc files
 odir=$SNODAS_DATA_DIR"/nc"
 mkdir -p $odir
 
 # Loop over .dat subdirs. 
 # Copy/pasta 'elif' block below and edit accordingly (e.g., units, long_name)
 # to include additional .dat subdirs.  Mind the character spacing on filenames! 
 # Filenames are not consistent across variables. 
 # PRLQ PRSL SWEM SNWZ
 for dirs in SWEM SNWZ
 do
	echo "Now in working in the $dirs directory"
 	FILES=${dirs}/*.dat
	
	# loop over fils in subdir
	for infiles in ${FILES}
	do
		echo "Working on $infiles"
		varn=`echo ${infiles} | cut -c 14-17`
		echo "And this variable code: $varn"
		pflg=`echo ${infiles} | cut -c 21-22`
		echo "This is a precip flag: $pflg"
		
		# Series of if/else follows for each variable. There's probably a more 
		# efficient way of doing this.
		
		# Liquid Precipitation (PRLQ)
		if [[ "$varn" == "1025" && "$pflg" == "00" ]];
		then
			# cut out and print filename (minus extension)
			Hdrfile=`echo ${infiles} | cut -c 6-48`
			echo "Now working on : $Hdrfile"
			
			# define the variable abbreviation for .nc files
			var=`echo PRCPL`
			echo "And this variable: ${var}"
	
			# extract date from filename and print to screen
			date=`echo $infiles | cut -c 34-41`
			echo "For this day: $date"
			
			# (1) copy generic ENVI header file to filename
			# place in working directory for gdal_translate
			cp $genhdr $dirs/$Hdrfile.hdr
			echo "created generic .hdr: $dirs/$Hdrfile.hdr"

			# (2) Generate command to convert binary dat (infile) to netCDF (outfile)
			ofile=`echo ${var}_snodas_${date}.nc`
			echo "Will use this for the .nc filename: $ofile"
                        # Check if masked or not
                        if [ "$masked" = true ] ; then
			    gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84' -a_nodata -9999 -A_ullr -124.7337 52.8754 -66.9421 24.9496 $infiles $odir/$ofile
                        else
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr -130.516666666661 58.2333333333310 -62.2499999999975 24.0999999999990 $infiles $odir/$ofile
                        fi
		
			# (3) Change name of variable in .nc file (defaults to band1)
			ncrename -v Band1,$var $odir/$ofile
			
			# (4) Change the long_name in .nc file (unfortunately doesn't look like spaces are allowed
			ncatted -O -a long_name,$var,o,c,"Liquid_Precipitation" $odir/$ofile
	
			# (5) Add units to new variable
			ncatted -a units,$var,c,c,"kgm-2" $odir/$ofile
	
		# else/if to move on to next variable
		elif [[ "$varn" == "1025" && "$pflg" == "01" ]];
		
		# Solid Precipitation
		then
			
			Hdrfile=`echo ${infiles} | cut -c 6-48`
			echo "Now working on : ${Hdrfile}"
			var=`echo PRCPS`
			echo "And this variable: ${var}"
			date=`echo ${infiles} | cut -c 34-41`
			echo "For this day: ${date}"
			
			# (1) copy generic ENVI header file to filename
			# place in working directory for gdal_translate
			cp $genhdr $dirs/$Hdrfile.hdr
			echo "created generic .hdr: $hdr"

			# (2) Generate command to convert binary dat (infile) to netCDF (outfile)
			ofile=`echo ${var}_snodas_${date}.nc`
			echo "Will use this for the .nc filename: $ofile"
	                # Check if masked or not
                        if [ "$masked" = true ] ; then
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84' -a_nodata -9999 -A_ullr -124.7337 52.8754 -66.9421 24.9496 $infiles $odir/$ofile
                        else
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr -130.516666666661 58.2333333333310 -62.2499999999975 24.0999999999990 $infiles $odir/$ofile
                        fi
	
			# (3) Change name of variable in .nc file (defaults to band1)
			ncrename -v Band1,$var $odir/$ofile
			
			# (4) Change the long_name in .nc file (unfortunately doesn't look like spaces are allowed
			ncatted -O -a long_name,$var,o,c,"Solid_Precipitation" $odir/$ofile
	
			# (5) Add units to new variable
			ncatted -a units,$var,c,c,"kgm-2" $odir/$ofile
	
		elif [[ "$varn" == "1034" ]];
		
		# Snow water equivalent
		then
		
			Hdrfile=`echo $infiles | cut -c 6-47`
			echo "Now working on : $Hdrfile"
			var=SWE
			echo "And this variable: $var"
			date=`echo $infiles | cut -c 33-40`
			echo "For this day: $date"
			
			# (1) copy generic ENVI header file to filename
			# place in working directory for gdal_translate
			cp $genhdr $dirs/$Hdrfile.hdr
			echo "created generic .hdr: $hdr"

			# (2) Generate command to convert binary dat (infile) to netCDF (outfile)
			ofile=`echo ${var}_snodas_${date}.nc`
			echo "Will use this for the .nc filename: $ofile"
	                # Check if masked or not
                        if [ "$masked" = true ] ; then
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84' -a_nodata -9999 -A_ullr -124.7337 52.8754 -66.9421 24.9496 $infiles $odir/$ofile
                        else
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr -130.516666666661 58.2333333333310 -62.2499999999975 24.0999999999990 $infiles $odir/$ofile
                        fi
	
			# (3) Change name of variable in .nc file (defaults to band1)
			ncrename -v Band1,$var $odir/$ofile
			
			# (4) Change the long_name in .nc file (unfortunately doesn't look like spaces are allowed
			ncatted -O -a long_name,$var,o,c,"Snow_Water_Equivalent" $odir/$ofile
			
			# (5) Add units to new variable
			ncatted -a units,${var},c,c,"mm" $odir/$ofile
			
		elif [[ "$varn" == "1036" ]];
		
		# Snow depth
		then
		
			Hdrfile=`echo $infiles | cut -c 6-47`
			echo "Now working on : $Hdrfile"
			var=SNWZ
			echo "And this variable: $var"
			date=`echo $infiles | cut -c 33-40`
			echo "For this day: $date"
			
			# (1) copy generic ENVI header file to filename
			# place in working directory for gdal_translate
			cp $genhdr $dirs/$Hdrfile.hdr
			echo "created generic .hdr: $hdr"

			# (2) Generate command to convert binary dat (infile) to netCDF (outfile)
			ofile=`echo ${var}_snodas_${date}.nc`
			echo "Will use this for the .nc filename: $ofile"
	                # Check if masked or not
                        if [ "$masked" = true ] ; then
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84' -a_nodata -9999 -A_ullr -124.7337 52.8754 -66.9421 24.9496 $infiles $odir/$ofile
                        else
                            gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr -130.516666666661 58.2333333333310 -62.2499999999975 24.0999999999990 $infiles $odir/$ofile
                        fi
	
			# (3) Change name of variable in .nc file (defaults to band1)
			ncrename -v Band1,$var $odir/$ofile
			
			# (4) Change the long_name in .nc file (unfortunately doesn't look like spaces are allowed
			ncatted -O -a long_name,$var,o,c,"Snow_Depth" $odir/$ofile
			
			# (5) Add units to new variable
			ncatted -a units,${var},c,c,"mm" $odir/$ofile
		else
			echo "None of your desired variables were found; check sub-directory abbreviations"
		fi

                # Add time dimension. Here we assume the output hour of the SNODAS files is at 06:00 UTC
                year=${date:0:4}
                month=${date:5:2}
                day=${date:7:2}
                date_format=${year}-${month}-${day} # make time format expected YYYY-MM-DD
                ncap2 -s "defdim(\"time\",-1);time[time]=0;time@long_name=\"Time\";time@timezone=\"UTC\";time@units=\"days since ${date_format} 06:00:00\"" -O $odir/$ofile $odir/$ofile'.temp'
                # Make time the record dimension and add to other variables
                ncwa -a time -O $odir/$ofile'.temp' $odir/$ofile
                ncecat -u time -O $odir/$ofile $odir/$ofile
                # Clean up
                rm -f $odir/$ofile'.temp'

                # Final option to subset netcdf file and remove original
                if [ $subset = true ]; then
                    echo "Subsetting netcdf file to user defined region"
                    sub_ofile="${ofile%.*}"
                    ncea -O -d lat,$lat_min,$lat_max -d lon,$lon_min,$lon_max $odir/$ofile $odir/$sub_ofile"_sub.nc"
                    
                    # Remove full extent file
                    echo "Removing full extent netcdf file"
                    rm -f $odir/$ofile   
                fi

	done  # loop over files in subdir	
			
 done	# loop over subdirs
	


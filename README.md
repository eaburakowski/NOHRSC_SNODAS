# NOHRSC_SNODAS
Scripts for retrieving and processing NOHRSC SNODAS daily binary files.  
Includes a number of scripts in bash, NCL, R, and/or matlab. 
This is a work in progress started in July 2017, so keep posted for additional scripts & edits. 
Codes will require customization and will not run as is. 
I'm happy to answer questions and welcome helpful suggestions for improving efficiency of any code:
elizabeth.burakowski@unh.edu

Files listed in order of use in my processing & analysis:

getSNODAS.sh 
- a short bash script for retrieving Nov-Apr (2004-2017) .tar files from the National Snow and Ice Data Center (NSIDC) ftp site. Uses wget.

untarSNODAS.sh
- bash script that untars and unzips SNODAS files. 
- moves all .Hdr files to a separate directory. I do this because the gdal_translate command usually spits out errors if the .Hdr file is in the same directory as the .dat files.  I haven't found a need for them yet.  
- moves all .dat files into separate subdirectories by variable.  

procSNODAS.sh
- bash script that converts .dat files to .nc using gdal_translate. Also uses nco's ncrename and ncatted.

addtimeSNODAS.ncl
- adds unlimited time dimension to .nc files created in procSNODAS.sh.  Surely there's a way to do it with NCO, but
  I found it to be easier in NCL. 
  
subsetSNODAS_avgSNWZ.ncl
- selects a regional subset from SNODAS files, calculates a seasonal (or monthly) mean, max, and min snow depth for each 
  season,and then calculates a climatological (well, 2004-2017) mean, max, and min for the period of record. 
- output is a single .nc file of the climatological mean, max, and min snow depth for regional subset.
- could combine with plotting script (plotNESNODAS.ncl) if region is small.

plotNESNODAS.ncl
- plots up map of seasonal or monthly average snow depth for region in US.  Output is .png graphic of data.

subsetSNODAS_avgSNWDAYS.ncl
- similar to subsetSNODAS_avgSNWZ.ncl, this script selects a regional subset from SNODAS files, calculates the number of   
  days per winter (Nov-Apr) with snow depth > user-defined threshold for each year in record (2004-2017), and then 
  calculates the climatological mean number of snow days > user-defined snow depth threshold. 
- output is a single .nc file of climatological mean number of snow days with snow depth > user-defined snow depth
- could combine with plotting script (plotNESNODAS_snowdays.ncl) if region is small. 

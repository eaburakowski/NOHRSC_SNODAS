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

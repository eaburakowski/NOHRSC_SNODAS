
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------------
;
; subsetSNODAS_avgSNWZ.ncl
; EA Burakowski
; 2017-08-07
;
; subsetSNODAS_avgSNWZ.ncl 
;	(1) selects a regional subset from the contiguous
; 	United States SNODAS dataset and 
;	(2) caculates a seasonal or monthly average, max, & min 
;	snow depth (SNWZ)
;	(3) calculates a climatological (well, 2003-2017) average, 
;	max, & min
;
; output is a single .nc file of the climatological average, max, &
; 	min snow depth, in mm, for regional subset for use with plotting scripts
; 	scripts (ie. plotNESNODAS.ncl)
;
;   * could probably combine plotting into the end of this script if
;     region is small.  
;
; ---------------------------------------------------------------------



;======================================================================
;                         The main code
;======================================================================

begin

;---A few constants
    years		= ispan(2004,2017,1)
    years!0		= "year"
    
   ;-- (1) select regional subset bounds (NE US below)
    latmin		= 38 
    latmax		= 50 
    lonmin		= -78 
    lonmax		= -66.9421 
    
   ;-- define variable and directory.  SNWZ = snow depth 
    var                = "SNWZ"
    dir                = "/net/nfs/yukon/raid5/data/NOHRSC_SNODAS/nc/"
    
   ;-- load a sample file to get dims & create empty array nyears x nlat x nlon
    a                   = addfile(dir+"/SNWZ_snodas_20140101.nc","r")
    b                   = a->SNWZ
    b_ne		= b({latmin:latmax},{lonmin:lonmax})
    lat			= a->lat({latmin:latmax})
    lon			= a->lon({lonmin:lonmax})

   ;-- create empty array to hold seasonal average for each year of record
    avg_seas          = new((/dimsizes(years),dimsizes(b_ne(:,0)),dimsizes(b_ne(0,:))/),float)
    avg_seas@_FillValue = -9999   
    avg_seas!0	= "year"
    avg_seas&year	= years
   
   ;-- create empty array to hold seasonal maximum for each year of record
    max_seas		= new((/dimsizes(years),dimsizes(b_ne(:,0)),dimsizes(b_ne(0,:))/),float)
    max_seas@_FillValue = -9999
    max_seas!0	= "year"
    max_seas&year	= years

   ;-- create empty array to hold seasonal minimum for each year of record
    min_seas		= new((/dimsizes(years),dimsizes(b_ne(:,0)),dimsizes(b_ne(0,:))/),float)
    min_seas@_FillValue = -9999
    min_seas!0	= "year"
    min_seas&year	= years

   ;-- create list of file names and split by yyyy, mm, dd
    f 		= systemfunc("cd "+dir+" ; ls "+var+"*.nc")
    yyyymmdd 	= toint(str_get_field(f,3,"_"))
    yyyy	= yyyymmdd/10000
    yyyymm	= yyyymmdd/100
    mm		= yyyymm-(yyyy*100)

   ;-- loop over years of record to calculate seasonal avg, max, and min
    do iyr=0,dimsizes(years)-2
	print("Working on "+years(iyr)+" and "+years(iyr+1))
	
       ;-- Seasonal Nov-Apr code	
        ;nd	= ind(yyyy.eq.years(iyr) .and. mm.ge.12)	; nov dec
	;jfma	= ind(yyyy.eq.years(iyr+1) .and. mm.le.3)	; jan feb mar apr
	;seas	= array_append_record(nd,jfma,0)		; season appended
       
       ;-- Monthly code,in this case, just January (mm.eq.1). 
       ;   Note starts in 2004 (no Jan 2003 data)	
        seas	= ind(yyyy.eq.years(iyr+1) .and. mm.eq.1)
        
       ;-- add all files for one season in loop, and concatenate
        fils 	= addfiles(dir+f(seas),"r")
	ListSetType(fils,"join")
	snwz	= fils[:]->SNWZ(:,{latmin:latmax},{lonmin:lonmax})
printVarSummary(snwz)

       ;-- (2) Calculate seasonal average, max, and min snow depth
        avg_seas(iyr,:,:)	= dim_avg_n_Wrap(snwz,0)
        max_seas(iyr,:,:)	= dim_max_n_Wrap(snwz,0)
        min_seas(iyr,:,:)	= dim_min_n_Wrap(snwz,0)

       ;-- Delete temporary variables at end of loop
       ;delete([/nd,jfma,seas,fils,snwz/]) 	; seasonal
       delete([/seas,fils,snwz/])		; monthly
    end do  ; years

 ;--- (3) Calculate 2004-2017 average snow depth
      avg_2004_2017	= dim_avg_n_Wrap(avg_seas,0)
      avgMax_2004_2017	= dim_avg_n_Wrap(max_seas,0)
      avgMin_2004_2017	= dim_avg_n_Wrap(min_seas,0)

 ;--- Write average snow depth, 2003-2017 to .nc file for plotting

    ;--- Filename for nc4 file. Change if not calculating January.
      fn 		= "NE_AvgMaxMin_Jan_"+var+"_"+years(0)+"-"+years(dimsizes(years)-1)+""
    
    ;--- Write variables to nc4 file
      setfileoption("nc","FileStructure","Advanced")
      setfileoption("nc","Format","NetCDF4")
 
    ;--- remove old file
      system("/bin/rm -f "+dir+fn+".nc")
      
    ;--- create new file   
      ncdf		= addfile(dir+fn+".nc","c")	
      fAtt		= True
      fAtt@title	= fn
      fAtt@orig_fil	= "us_ssmv11036tS__T0001TTNATS*05HP001.dat"
      fAtt@Conventions	= "COARDS/CF-1.0"
      fAtt@creation_date= systemfunc("date")
      fAtt@author	= "Elizabeth Burakowski (elizabeth.burakowski@unh.edu)"
      
    ;--- file attribute, description. Change appropriately
      fAtt@description 	= "Average, Max, & Min January "+var+" [snow depth] in mm, "+years(0)+"-"+years(dimsizes(years)-1)+""
      
    ;--- file attributes, size
      fileattdef(ncdf,fAtt)
      dimNames		= (/"lat", "lon"/)
      dimSizes		= (/ dimsizes(b_ne(:,0)), dimsizes(b_ne(0,:)) /)
      dimUnlim          = (/ False, False /)
      filedimdef(ncdf,dimNames,dimSizes,dimUnlim)

    ;--- Define file variables
      filevardef(ncdf,"lat",typeof(lat),getvardims(lat))
      filevardef(ncdf,"lon",typeof(lon),getvardims(lon))
      filevardef(ncdf,"avg_snwz",typeof(avg_2004_2017),getvardims(avg_2004_2017))
      filevardef(ncdf,"max_snwz",typeof(avgMax_2004_2017),getvardims(avgMax_2004_2017))
      filevardef(ncdf,"min_snwz",typeof(avgMin_2004_2017),getvardims(avgMin_2004_2017))
      
    ;--- Define file attributes
      filevarattdef(ncdf,"lat",lat)
      filevarattdef(ncdf,"lon",lon)
      filevarattdef(ncdf,"avg_snwz",avg_2004_2017)
      filevarattdef(ncdf,"max_snwz",avgMax_2004_2017)
      filevarattdef(ncdf,"min_snwz",avgMin_2004_2017)
      
      setfileoption(ncdf,"DefineMode",False)
      
    ;--- write variable to file
      ncdf->lat		= (/lat/)
      ncdf->lon	 	= (/lon/)
      ncdf->avg_snwz	= (/avg_2004_2017/)
      ncdf->max_snwz	= (/avgMax_2004_2017/)
      ncdf->min_snwz	= (/avgMin_2004_2017/)

end


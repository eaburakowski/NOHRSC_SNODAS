
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

;======================================================================
;                         The main code
;======================================================================

begin

;---A few constants
    years		= ispan(2004,2017,1)
    years!0		= "year"
    latmin		= 38 ; 42.647  ; 38 
    latmax		= 50 ; 45.481  ; 50
    lonmin		= -78 ; -72.702  ; -78
    lonmax		= -66.9421 ; -70.428  ; -66.9421
    var                = "SNWZ"
    dir                = "/net/nfs/yukon/raid5/data/NOHRSC_SNODAS/nc/"
    
   ;-- load a sample file to get dims & create empty array nyears x nlat x nlon
    a                   = addfile(dir+"/SNWZ_snodas_20140101.nc","r")
    b                   = a->SNWZ
    b_ne		= b({latmin:latmax},{lonmin:lonmax})
    lat			= a->lat({latmin:latmax})
    lon			= a->lon({lonmin:lonmax})
print("min lat = "+min(lat))
print("max lat = "+max(lat))
print("min lon = "+min(lon))
print("max lon = "+max(lon))



    avg_ndjfma          = new((/dimsizes(years),dimsizes(b_ne(:,0)),dimsizes(b_ne(0,:))/),float)
    avg_ndjfma@_FillValue = -9999   
    avg_ndjfma!0	= "year"
    avg_ndjfma&year	= years
printVarSummary(avg_ndjfma)

   ;-- create list of file names and split by var, yyyy, mm, dd
    f 		= systemfunc("cd "+dir+" ; ls "+var+"*.nc")
    yyyymmdd 	= toint(str_get_field(f,3,"_"))
    yyyy	= yyyymmdd/10000
    yyyymm	= yyyymmdd/100
    mm		= yyyymm-(yyyy*100)

    do iyr=0,dimsizes(years)-2
	print("Working on "+years(iyr)+" and "+years(iyr+1))
        ;nd	= ind(yyyy.eq.years(iyr) .and. mm.ge.12)	; nov dec
	;jfma	= ind(yyyy.eq.years(iyr+1) .and. mm.le.3)	; jan feb mar apr
        n_a	= ind(yyyy.eq.years(iyr+1) .and. mm.eq.1)
        ;n_a	= array_append_record(nd,jfma,0)
	print(dimsizes(n_a))
        fils 	= addfiles(dir+f(n_a),"r")
	ListSetType(fils,"join")
	snwz	= fils[:]->SNWZ(:,{latmin:latmax},{lonmin:lonmax})
printVarSummary(snwz)

       ;-- Calculate seasonal average snow depth
        avg_ndjfma(iyr,:,:)	= dim_avg_n_Wrap(snwz,0)

       ;-- Delete temporary variables at end of loop
       ;delete([/nd,jfma,n_a,fils,snwz/])
       delete([/n_a,fils,snwz/])
    end do  ; years

printVarSummary(avg_ndjfma)
print("Min avg Dec-Mar snow depth = "+min(avg_ndjfma))
print("Max avg Dec-Mar snow depth = "+max(avg_ndjfma))

 ;--- Calculate 2004-2017 average snow depth
      avg_2004_2017	= dim_avg_n_Wrap(avg_ndjfma,0)
printVarSummary(avg_2004_2017)

 ;--- Write average snow depth, 2003-2017 to .nc file for plotting

    ;--- Filename for nc4 file
      fn 		= "NE_Avg_Jan_"+var+"_"+years(0)+"-"+years(dimsizes(years)-1)+""
    
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
      
      fAtt@description 	= "Average December through March, "+var+" [snow depth] in meters, "+years(0)+"-"+years(dimsizes(years)-1)+""
      
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

    ;--- Define file attributes
      filevarattdef(ncdf,"lat",lat)
      filevarattdef(ncdf,"lon",lon)
      filevarattdef(ncdf,"avg_snwz",avg_2004_2017)

      setfileoption(ncdf,"DefineMode",False)
      
    ;--- write variable to file
      ncdf->lat		= (/lat/)
      ncdf->lon	 	= (/lon/)
      ncdf->avg_snwz	= (/avg_2004_2017/)

end


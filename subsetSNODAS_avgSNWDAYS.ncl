
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;----------------------------------------------------------------------
;
; subsetSNODAS_avgSNWDAYS.ncl
; EA Burakowski
; 2017-08-15
;
; subsetSNODAS_avgSNWDAYS.ncl 
;	(1) selects a regional subset from the contiguous
; 	United States SNODAS dataset and 
;	(2) caculates a seasonal or monthly number of days with snow
;	depth greater than [threshold] mm.
;	(3) calculates a climatological (well, 2003-2017) snow days
;
; output is a single .nc file of the climatological snow dayss
;
;----------------------------------------------------------------------

;==================================================================
;
; SnowDays function
;   - E Burakowski
;     2017-08-15
; 
;==================================================================

undef("SnowDays")
function SnowDays(x[*][*][*]:numeric,thresh[1]:numeric)
local dimx, ntim, nlat, mlon, snwd, nl, ml, ii

begin
  dimx 	= dimsizes(x)
  ntim	= dimx(0)
  nlat	= dimx(1)
  mlon	= dimx(2)
  
  snwd	= new( dimx(1:2), "integer", -9999)
  
  do nl=0,nlat-1,1
    do ml=0,mlon-1,1
      ii := ind(x(:,nl,ml) .ge. thresh)
      if (.not.ismissing(ii(0))) then
        nii = dimsizes(ii)
	snwd(nl,ml) = nii
      end if
    end do ; lon
  end do ; lat
  
  snwd@long_name	= "Days per winter (Nov - Apr) with snow depth > "+thresh
  snwd@units		= "days per winter"
  snwd!0		= "lat"
  snwd&lat		= x&lat
  snwd!1		= "lon"
  snwd&lon		= x&lon
  return(snwd)

end

;======================================================================
;                         The main code
;======================================================================

begin

;---A few constants
    thresh		= 200	; minimum snow depth threshold, in mm
    years		= ispan(2004,2017,1)
    years!0		= "year"
    
   ;-- (1) select regional subset bounds (Northeast below)
    latmin		= 30   
    latmax		= 50  
    lonmin		= -80 
    lonmax		= -66 
   
   ;-- define variable and directory.  SNWZ = snow depth 
    var			= "SNWZ"
    dir                	= "/net/nfs/yukon/raid5/data/NOHRSC_SNODAS/nc/"
    odir		= "/net/home/eos/ean2/SNODAS_processed/"
    
   ;-- load a sample file to get dims & create empty array nyears x nlat x nlon
    a                   = addfile(dir+"/SNWZ_snodas_20140101.nc","r")
    b                   = a->SNWZ({latmin:latmax},{lonmin:lonmax})
    lat			= a->lat({latmin:latmax})
    lon			= a->lon({lonmin:lonmax})

   ;-- create empty array to hold seasonal total days with snow for each year of record
    snwdays          	= new((/dimsizes(years),dimsizes(b(:,0)),dimsizes(b(0,:))/),float)
    snwdays@_FillValue 	= -9999   
    snwdays!0		= "year"
    snwdays&year	= years

   ;-- create list of file names and split to obtain yyyy, mm, dd
    f 		= systemfunc("cd "+dir+" ; ls "+var+"*.nc")
    yyyymmdd 	= toint(str_get_field(f,3,"_"))
    yyyy	= yyyymmdd/10000
    yyyymm	= yyyymmdd/100
    mm		= yyyymm-(yyyy*100)

   ;-- loop over years of record to calculate seasonal avg, max, and min
    do iyr=0,dimsizes(years)-2
	print("Working on "+years(iyr)+" and "+years(iyr+1))
	
       ;-- Seasonal Nov-Apr code	
        nd	= ind(yyyy.eq.years(iyr) .and. mm.ge.11)	; nov dec
	jfma	= ind(yyyy.eq.years(iyr+1) .and. mm.le.4)	; jan feb mar apr
	seas	= array_append_record(nd,jfma,0)		; season appended
       
       ;-- add all files for one season in loop, and concatenate
        fils 	= addfiles(dir+f(seas),"r")
	ListSetType(fils,"join")
	snwz		= fils[:]->SNWZ(:,{latmin:latmax},{lonmin:lonmax})
	snwz!0		= "days"
	snwz&days	= ispan(1,dimsizes(seas),1)
printVarSummary(snwz)

       ;-- (2) Get indices of days > threshold
        snwdays(iyr,:,:)	= SnowDays(snwz,200)

print("Max snow days for year "+years(iyr)+" = "+max(snwdays(iyr,:,:)))
print("Min snow days for year "+years(iyr)+" = "+min(snwdays(iyr,:,:)))

       ;-- Delete temporary variables at end of loop
        delete([/nd,jfma,seas,fils,snwz/])
       
    end do  ; years

printVarSummary(snwdays)

 ;--- (3) Calculate 2004-2017 average snow depth
      snowdays_2004_2017= dim_avg_n_Wrap(snwdays,0)
      
printVarSummary(snowdays_2004_2017)
print("Max Snow Days = "+max(snowdays_2004_2017))
print("Min Snow Days = "+min(snowdays_2004_2017))


;----------------------------------------------------------------------
; Plotting options section
;----------------------------------------------------------------------

       pltType = "png"                                  ; plot type
       pltDir = "./"                                   ; plot directory
       pltName = "NE_SnowDays_Nov-Apr_SNWZGT200_2004-2017"                   ; plot name (ps file)
       pltPath = pltDir+pltName                        ; plot path

   wks = gsn_open_wks(pltType,pltPath)              ; create workstation for ps file

       gsn_define_colormap(wks,"MPL_cool")      ; define color table 

        res = True
	
	res@gsnMaximize		 = True
        res@gsnDraw              = False
        res@gsnFrame             = False

        res@cnFillOn             = True              ; color plot desired
        res@cnLinesOn            = True             ; turn off contour lines
        res@cnLineLabelsOn       = True             ; turn off contour labels
        res@cnInfoLabelOn        = False             ; turn off info label (top labels of indvid. plots)
        res@cnFillMode           = "RasterFill"      ; turn raster on
        res@cnLevelSelectionMode = "ManualLevels"    ; Set contour levels manually
        res@cnMinLevelValF       = 0                 ; minimum contour, mm
        res@cnMaxLevelValF       = 180               ; maximum contour, mm 
	res@cnLevelSpacingF	 = 20		     ; countour interval (100 mm)
	res@lbLabelBarOn	 = True
	res@mpOutlineOn		 = True
	res@mpDataBaseVersion	 = "MediumRes"
	res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
	res@mpProjection	 = "CylindricalEquidistant"
        bndadd			 = 0.25
        res@mpLimitMode           = "LatLon"           ; required
        res@mpMinLatF             = latmin-bndadd
        res@mpMaxLatF             = latmax+bndadd
        res@mpMinLonF             = lonmin-bndadd
        res@mpMaxLonF             = lonmax+bndadd
        res@mpCenterLonF          = (lonmin + lonmax)*0.5
        res@mpCenterLatF          = (latmin + latmax)*0.5
	res@pmTickMarkDisplayMode = "Always"
	res@tmXTOn		  = False
	res@tmYLOn		  = False
	
	
	res@gsnLeftString         = ""                ; Turn off left subtitle
        res@gsnRightString        = ""                ; Turn off right subtitle
        res@gsnMajorLatSpacing    = 1
        res@gsnMajorLonSpacing    = 1
        res@gsnMinorLonSpacing    = 1
	
        res@gsnAddCyclic          = False             ; regional grid (changes central meridian)/xwo

        plot = gsn_csm_contour_map(wks,snowdays_2004_2017,res) 

draw(plot)
frame(wks)  


 ;--- Write average snow depth, 2003-2017 to .nc file for plotting

    ;--- Filename for nc4 file. Change if not calculating January.
      fn 		= "NE_SnowDays_Nov-Apr_"+var+"GT"+thresh+"_mm_"+years(0)+"-"+years(dimsizes(years)-1)+""
    
    ;--- Write variables to nc4 file
      setfileoption("nc","FileStructure","Advanced")
      setfileoption("nc","Format","NetCDF4")
 
    ;--- remove old file
      system("/bin/rm -f "+odir+fn+".nc")
      
    ;--- create new file   
      ncdf		= addfile(odir+fn+".nc","c")	
      fAtt		= True
      fAtt@title	= fn
      fAtt@orig_fil	= "us_ssmv11036tS__T0001TTNATS*05HP001.dat"
      fAtt@Conventions	= "COARDS/CF-1.0"
      fAtt@creation_date= systemfunc("date")
      fAtt@author	= "Elizabeth Burakowski (elizabeth.burakowski@unh.edu)"
      
    ;--- file attribute, description. Change appropriately
      fAtt@description 	= "Average snow days "+var+" greater than "+thresh+" mm, "+years(0)+"-"+years(dimsizes(years)-1)+""
      
    ;--- file attributes, size
      fileattdef(ncdf,fAtt)
      dimNames		= (/"lat", "lon"/)
      dimSizes		= (/ dimsizes(b(:,0)), dimsizes(b(0,:)) /)
      dimUnlim          = (/ False, False /)
      filedimdef(ncdf,dimNames,dimSizes,dimUnlim)


    ;--- Define file variables
      filevardef(ncdf,"lat",typeof(lat),getvardims(lat))
      filevardef(ncdf,"lon",typeof(lon),getvardims(lon))
      filevardef(ncdf,"SnowDays",typeof(snowdays_2004_2017),getvardims(snowdays_2004_2017))
      
    ;--- Define file attributes
      filevarattdef(ncdf,"lat",lat)
      filevarattdef(ncdf,"lon",lon)
      filevarattdef(ncdf,"SnowDays",snowdays_2004_2017)
      
      setfileoption(ncdf,"DefineMode",False)
      
    ;--- write variable to file
      ncdf->lat		= (/lat/)
      ncdf->lon	 	= (/lon/)
      ncdf->SnowDays	= (/snowdays_2004_2017/)

end


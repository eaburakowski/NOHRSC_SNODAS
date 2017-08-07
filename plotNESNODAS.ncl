
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

;======================================================================
;                         The main code
;======================================================================

begin

;---A few constants
    dir                = "/net/nfs/yukon/raid5/data/NOHRSC_SNODAS/nc/"
    
   ;-- load avg snow depth file 
    a                   = addfile(dir+"NE_Avg_Jan_SNWZ_2004-2017.nc","r")
    avgSnwz		= a->avg_snwz

printVarSummary(avgSnwz)

    lat = a->lat
    lon	= a->lon
    minlat = 40
    maxlat = 47.6
    minlon = -76.5
    maxlon = max(lon)
    bndadd = 0.25

;----------------------------------------------------------------------
; Plotting options section
;----------------------------------------------------------------------

       pltType = "png"                                  ; plot type
       pltDir = "./"                                   ; plot directory
       pltName = "NE_Jan_Avg_SNWZ_2004-2017"                   ; plot name (ps file)
       pltPath = pltDir+pltName                        ; plot path

   wks = gsn_open_wks(pltType,pltPath)              ; create workstation for ps file

       gsn_define_colormap(wks,"MPL_cool")      ; define color table 

        res = True
	
	res@gsnMaximize		 = True
        res@gsnDraw              = False
        res@gsnFrame             = False

        res@cnFillOn             = True              ; color plot desired
        res@cnLinesOn            = False             ; turn off contour lines
        res@cnLineLabelsOn       = False             ; turn off contour labels
        res@cnInfoLabelOn        = False             ; turn off info label (top labels of indvid. plots)
        res@cnFillMode           = "RasterFill"      ; turn raster on
        res@cnLevelSelectionMode = "ManualLevels"    ; Set contour levels manually
        res@cnMinLevelValF       = 0                 ; minimum contour, mm
        res@cnMaxLevelValF       = 650               ; maximum contour, mm 
	res@cnLevelSpacingF	 = 100		     ; countour interval (100 mm)
	res@lbLabelBarOn	 = True
	res@mpOutlineOn		 = True
	res@mpDataBaseVersion	 = "MediumRes"
	res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
	res@mpProjection	 = "CylindricalEquidistant"
       
        res@mpLimitMode           = "LatLon"           ; required
        res@mpMinLatF             = minlat-bndadd
        res@mpMaxLatF             = maxlat+bndadd
        res@mpMinLonF             = minlon-bndadd
        res@mpMaxLonF             = maxlon+bndadd
        res@mpCenterLonF          = (minlon + maxlon)*0.5
        res@mpCenterLatF          = (minlat + maxlat)*0.5
	res@pmTickMarkDisplayMode = "Always"
	res@tmXTOn		  = False
	res@tmYLOn		  = False
	
	
	res@gsnLeftString         = ""                ; Turn off left subtitle
        res@gsnRightString        = ""                ; Turn off right subtitle
        res@gsnMajorLatSpacing    = 1
        res@gsnMajorLonSpacing    = 1
        res@gsnMinorLonSpacing    = 1
	
        res@gsnAddCyclic          = False             ; regional grid (changes central meridian)/xwo

        plot = gsn_csm_contour_map(wks,avgSnwz,res) 

draw(plot)
frame(wks)  

end

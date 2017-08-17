
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;======================================================================
;                         The main code
;======================================================================

begin

;---A few constants
    dir                = "/net/home/eos/ean2/SNODAS_processed/nc/"
    
   ;-- load avg snow depth file 
    a                   = addfile(dir+"NE_SnowDays_Nov-Apr_SNWZGT200_mm_2004-2017.nc","r")
    avgSnowDays		= a->SnowDays

printVarSummary(avgSnowDays)

    lat = a->lat
    lon	= a->lon
    minlat = 35
    maxlat = 47.5
    minlon = -79
    maxlon = max(lon)
    bndadd = 0.25

;----------------------------------------------------------------------
; Plotting options section
;----------------------------------------------------------------------

       pltType = "png"                                  ; plot type
       pltDir = "/net/home/eos/ean2/SNODAS_processed/figures/"                                   ; plot directory
       pltName = "NE_SnowDays_Nov-Apr_SNWZGT200_2004-2017"                   ; plot name (ps file)
       pltPath = pltDir+pltName                        ; plot path

   wks = gsn_open_wks(pltType,pltPath)              ; create workstation for ps file

       gsn_define_colormap(wks,"MPL_cool")      ; define color table 

        res = True
	
	res@gsnMaximize		 = True
        res@gsnDraw              = False
        res@gsnFrame             = False

      ;-- Contour fill properties
        res@cnFillOn             = True              ; color plot desired
	res@cnInfoLabelOn        = False             ; turn off info label (top labels of indvid. plots)
        res@cnFillMode           = "RasterFill"      ; turn raster on
	res@gsnContourZeroLineThicknessF	= 2

      ;-- Contour levels
        res@cnLinesOn            = True             ; turn off contour lines
        res@cnLineLabelsOn       = True             ; turn off contour labels
	res@cnLevelSelectionMode = "ManualLevels"    ; Set contour levels manually
        res@cnMinLevelValF       = 0                 ; minimum contour, mm
        res@cnMaxLevelValF       = 180               ; maximum contour, mm 
	res@cnLevelSpacingF	 = 20		     ; countour interval (100 mm)
	res@cnLevelFlags	 = (/"LineOnly","LineOnly","NoLine","NoLine","NoLine","NoLine",\
				     "NoLine","NoLine","NoLine","NoLine"/)
      ;-- Label bar properties	
	res@lbLabelBarOn	 = True
	res@lbOrientation	 = "Horizontal"
	res@pmLabelBarWidthF	 = 0.4

      ;-- Map state outlines
	res@mpOutlineOn		 = True
	res@mpDataBaseVersion	 = "MediumRes"
	res@mpOutlineBoundarySets = "GeophysicalAndUSStates"
	res@mpProjection	 = "CylindricalEquidistant"
      
      ;-- Map domain boundaries, grid/tick properties 
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
	
      ;-- Labels & titles
	res@gsnLeftString         = ""                ; Turn off left subtitle
        res@gsnRightString        = ""                ; Turn off right subtitle
        res@gsnMajorLatSpacing    = 1
        res@gsnMajorLonSpacing    = 1
        res@gsnMinorLonSpacing    = 1
	
        res@gsnAddCyclic          = False             ; regional grid (changes central meridian)/xwo

        plot = gsn_csm_contour_map(wks,avgSnowDays,res) 

draw(plot)
frame(wks)  

end

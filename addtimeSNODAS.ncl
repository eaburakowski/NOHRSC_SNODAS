
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; ---------------------------------------------------------------------
;
; addtimeSNODAS.ncl
;
; adds an unlimited time dimension to SNODAS .nc files created using
;   procSNODAS.sh.  
;   - filename must conform to $VAR_snodas_$yyyymmdd.nc
;   - where $VAR is a variable abbreviation of any length
;   - $yyyymmdd is the year, month, day of the daily file
;
; ---------------------------------------------------------------------

;======================================================================
;                         The main code
;======================================================================

begin

 ;--- A few constants
      
   ;-- Directory where .nc files are stored
   dir 	= "/net/nfs/yukon/raid5/data/NOHRSC_SNODAS/nc/"
   fils	= systemfunc("cd "+dir+" ; ls SWEM*.nc")

 ;--- Loop over files
   do i = 0,dimsizes(fils)-1

      ;--- extract date from filename
         yyyymmdd	= toint(str_get_field(fils(i),3,"_"))
         yyyy		= yyyymmdd/10000
         mmdd		= yyyymmdd-yyyy*10000
         mm		= mmdd/100
         dd		= mmdd-mm*100
         hh		= dd
         mn 		= dd
         sc		= dd
         hh		= 0
         mn 		= 0
         sc		= 0

      ;--- assign units
         units 		= "days since 2003-01-01"

      ;--- convert yyyymmdd to new units
         time = cd_inv_calendar(yyyy,mm,dd,hh,mn,sc,units,0)
         
      ;--- add file to write
         a 	= addfile(dir+fils(i),"w")	
      
      ;--- add unlimited time dimension to file
         filedimdef(a,"time",-1,True)
         a->time = time

 end do  ; fils

end




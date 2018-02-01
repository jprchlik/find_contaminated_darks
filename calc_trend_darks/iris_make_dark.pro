
pro iris_make_dark, index, dark, temps, time_tab, temp_tab, levels, $
	progver = progver

; ==============================================================================
;+
; PROJECT: 
;
;     IRIS
;
; NAME:
;
;     IRIS_MAKE_DARK
;
; CATEGORY:
;
;       Data calibration
;
; PURPOSE:
;
;       Create a suitable averaged dark frame for a given set of spacecraft 
;       temperatures and exposure time
;  
; CALLING SEQUENCE:
;
; INPUTS:
;
;         INDEX:  [mandatory] IRIS type index structure of the data array 
;                 for which you want a dark generated (a single index).
;       TIME_TAB: [optional] string array of N tabulated times for averaged
;                 temperatures spanning INDEX.DATE_OBS and one hour previous,
;                 found currently (9/2013) at
;                 http://www.lmsal.com/~boerner/iris/temps/
;                 The program preferentially works from TIME_TAB and TEMP_TAB
;                 if present.
;       TEMP_TAB: [optional] array of [6,N] tabulated temperatures 
;                 (ITF1CCD1, ITF2CCD2, ITNUCCD3, ITSJCCD4, BT06CBPX, and
;                 BT07CBNX for averaged temperatures found currently (9/2013) 
;                 at http://www.lmsal.com/~boerner/iris/temps/
;                 The program preferentially works from TIME_TAB and TEMP_TAB
;                 if present.
;         TEMPS:   [optional] fltarr(12) of system temperatures appropriate
;                 to data connected to INDEX.  (If not present, or all zero,
;                 temperatures are taken the INDEX).
;                 Currently, the temperatures required are:
;                 TCCD[0] = index.ITF1CCD1  (CCD1_FUV1_OPERATING)
;                 TCCD[1] = index.ITF2CCD2 (CCD2_FUV2_OPERATING)
;                 TCCD[2] = index.ITNUCCD3 (CCD3_NUV_OPERATING)
;                 TCCD[3] = index.ITSJCCD4 (CCD4_SJI_OPERATING)
;                 TCCD[4] = index.BT06CBPX  (CEB_ON_THE_POSX_AXIS)
;                 TCCD[5] = index.BT06CBPX  (same, from 50 min before 
;                                                INDEX.DATE_OBS)
;                 TCCD[6] = index.BT06CBPX  (same, from 35 min ago)
;                 TCCD[7] = index.BT06CBPX  (same, from 45 min ago)
;                 TCCD[8] = index.BT07CBNX  (CEB_ON_THE_NEGX_AXIS, 8 min ago)
;                 TCCD[9] = index.BT07CBNX  (same, from 23 ninutes ago)
;                 TCCD[10] = index.BT07CBNX  (same, from 48 ninutes ago)
;                 TCCD[11] = index.BT07CBNX  (same, from 14 ninutes ago)
;                 These temperatures can be found (currently, 8/2013,
;                 when not in the headers) at:
;
;   for the "final product", use TIME_TAB and TEMP_TAB as input
;   for "quick look", pass in values for TCCD (or if absent, they are
;   assumed in the INDEX and taken from there - not getting the time shifts!)
; 
; OUTPUTS: 
;
;         DARK:  [mandatory] A full frame averaged dark frame 
;                appropriate to INDEX (and potentially TCCD).
;         TEMPS:   [optional] fltarr(12) of system temperatures appropriate
;                 to data connected to INDEX.  (computed if TIME_TAB and
;                 TEMP_TAB are present)
;       LEVELS:  [optional] 2x4 floating point array containing calculated 
;                average levels of pedestals and dark currents by quadrant:
;                 levels[0,*] = pedestal in read ports [E, F, H, G]
;                 levels[1,*] = dark current in read ports [E, F, H, G]
;                (note: total average active dark level, avg, is thus given by
;                 avg = total(levels, 1) 
;                 Note that in this calibration: the "pedestal" is taken from
;                 t~0s darks)
;           
;
; OPTIONAL INPUT KEYWORD PARAMETERS:
;                 None
;
; OPTIONAL OUTPUT KEYWORD PARAMETERS:
;         PROGVER:   String describing the version of this routine that was run
;
; EXAMPLES:
;             If you have vectors of averaged temperatures for the last
;               hour and predicted levels:
;                 iris_make_dark,index,dark,temps,time_tab,temp_tab,levels
;               (interpolated & shifted temps will be output)
;
;             If they arent, make a temps vector as described above and use:
;                 iris_make_dark,index,dark,temps,dum,dum,levels
;               (where dum is a "dummy" nonexisting variable)
;
;             If system temperatures are already in index structure, use:
;                 iris_make_dark,index,dark
;             (note this will not work optimally, since the time shifted 
;             pedestal temperatures will not be in the header values)
;
; COMMON BLOCKS:
;       IRIS_DARK_CB:   containing a structure DARKSTR which holds the "base
;                       level" averaged darks and various calibration parameters
;
;
; PROCEDURE:
;
;             IRIS_MAKE_DARK reads in an averaged dark file based on
;             instrume, date_obs and other information in INDEX.  This averaged 
;             dark has been adjusted to specific temperature values; this
;             procedure applied empirical correlations for the pedestal and 
;             dark current in each CCD read port to adjust each section of
;             the dark to the temperatures and exposure time apporpiate
;             for the input INDEX.  Currently works on a single index only.
;             It can optionally also output average pedestal and dark current
;             levels.  
;            
;
; NOTES:
;
;             Averaged dark files are currently based on 19 darks with
;             exposures < 0.5s; the full calibrations for all CCD ports vs. 
;             temperature, and exposure time is based on 152 darks.  Only one 
;             epoch was calibrated fully, with pedestal offsets to the previous
;             epoch.  CCD DN rates, which on the ground were temperature
;             dependent, here are averaged constants due to the small range
;             of on orbit CCD temperatures currently sampled (as of 08/09/13).
;             A few hot or cold pixels, and pixels which showed large
;             standard deviations in the averages, have been replaced by
;             the respective read port median (v2).
;
;             Calibrations will be improved as more data, and a larger
;             range of on-orbit conditions become available and are analyzed.
; 
;
;
; CONTACT:
;
;       Comments, feedback, and bug reports regarding this routine may be
;       directed to this email address (temporarily): saar@cfa.harvard.edu 
;
; MODIFICATION HISTORY:
;
progver = 'v2013.Aug.09' ;--- (SSaar) Written.
progver = 'v2013.Aug.18' ;--- (SSaar) Removed hot, cold, and high RMS pixels
;                               from averaged darks. Added note above, fixed
;                               an erroneously labeled temperature, improved
;                               description above.
progver = 'v2013.Aug.21' ;--- (SSaar) Fixed erroneously labeled temperatures.  
progver = 'v2013.Aug.22' ;--- S.L.Freeland - $SSW tranportability
progver = 'v2013.Aug.26' ;--- P.Boerner - store data in a common block
progver = 'v2013.Sep.20' ;--- (SSaar) - Major recalibration including dark
;                              "reshaping". Program now also treats data with 
;                              binning and cuts it to the appropriate size 
;                              if needed (for NUV or SJI), and optionally
;                              ouputs average pedestal and dark current levels
;                              and interpolated temperatures used.  Checks
;                              for bad temperatures, and replaces these with 
;                              seasonal averages. 
progver	= 'v2013.Sep.24'  ;--- S.L.Freeland - fix tag_exist calling error 
progver	= 'v2013.Sep.26'  ;--- P.Boerner - fix number of elements in tccd
progver	= 'v2013.Sep.28'  ;--- S.Saar - change bad temperature test to improve
;                               rejection of bad temperatures.
progver	= 'v2014.Sep.24'  ;--- S.Saar - add fix for long-term variations 
; 
progver = 'v2015.Oct.05'  ;--- S.Saar - useing update to iris_dark_trend_fix (S.saar date 30.Sep.2015, onlined 10/5/15)..   ; RPT whoops, should have marked something for this when I onlined it, didn't until 11/04/15.   
progver	= 'v2015.Nov.25'  ;--- S.Saar - add offsets by spatial summing
;                                
;
;-
; ============================================================================



tint=index.int_time                    ; dark integration time
ins = index.instrume eq 'FUV'          ; instrument (FUV or NUV/SJI)
date0=index.date_obs                   ; obs date
nspec=index.sumsptrl                 ; binning in spectral dimension
nspat=index.sumspat                  ; binning in spatial dimension

tdate=anytim(date0)                  ; obs time in s



;tdatebnd1='2013-07-26T23:26:00.00Z'

;moo=1    ; ***kill
;if moo ne 1 then begin    ; ***kill


common iris_dark_cb, darkstr

if n_elements(darkstr) eq 0 then iris_prep_read_darks

if ins eq 1 then thisdarkstr = darkstr.fuv else thisdarkstr = darkstr.nuv

dark = thisdarkstr.dark		     ; restore correct averaged dark data file
tbnd0 = thisdarkstr.tbnd0      	     ; ( currently in IDL save files, contain 
                                     ;  avg dark array: dark[4144,1096,ntime] 
cped = thisdarkstr.cped		     ;  time boundary array: tbnd0[ntime]
cd = thisdarkstr.cd		     ;  pedestal and dark current temperature
sl1 = thisdarkstr.sl1  	             ;    polynomial coefficients: 
sl2 = thisdarkstr.sl2                ;    cped[2,4,ntime] and c0[2,4,ntime] 
it = thisdarkstr.it		     ;  Dark current slope coefficients: 
                                     ;   sl1[2,4,ntime] and sl1[2,4,ntime] 
                                     ; temperature index:  it [8]
poff = thisdarkstr.poff              ;  pedestal offsets: poff [4,ntime] 
dt = thisdarkstr.dt                  ;   times shifts dt[12,ntime]
                                     ; to be updated as CCD pedestal,  
				     ; calibration, etc, change

;endif    ; ***kill

; *****TEMPORARY****
;if ins eq 1 then restore,'dark_avg_fuv.new.dat' else $
;   restore,'dark_avg_nuv.new.dat'

dt=reform(dt)

tbnd = anytim(tbnd0)                   ; boundary dates for different pedestals
indt = where(tdate le tbnd)
indt = indt[0]                         ; find correct time index
                                       ; use time index to get correct epoch of
d0=reform(dark(*,*,indt))              ; baseline averaged dark @ tset
cp = reform(cped[*,*,indt])            ; pedestal(temps) poly coeffs
cd = reform(cd[*,*,indt])              ; dark current(temps) poly coeffs
csl1 = reform(sl1[*,*,indt])          ; dark slope1 poly coeffs
csl2 = reform(sl2[*,*,indt])          ; dark slope2 poly coeffs
poff = reform(poff[*,indt])          ; epoch pedestal offset
dt = reform(dt[*,indt])               ; epoch time shifts


; if indt eq 0 and ins eq 1 then poff=[0,21.94,19.4,21.87]

nt = n_elements(temps)
ntab = n_elements(time_tab)

it0=[0,1,2,3,4,4,4,4,5,5,5,5]             ; which temp to select
if ntab eq 0 then begin              ; if CCD temperature tables undefined...
  from_ind = 0
  if nt eq 0 then from_ind=1
  if nt eq 1 then if total(temps) eq 0 then from_ind = 1 
                                     ; if temps not there or =0s, get from index
  if from_ind eq 1 then begin
     good_ind =tag_exist(index,'ITF1CCD1') ; check if good index (has temp tags) 
     if good_ind eq 1 then begin
        tccd = fltarr(12)                    ; set it up from index
        tccd[0] = index.ITF1CCD1             ; CCD1_FUV1_OPERATING
        tccd[1] = index.ITF2CCD2             ; CCD2_FUV2_OPERATING
        tccd[2] = index.ITNUCCD3             ; CCD3_NUV_OPERATING
        tccd[3] = index.ITSJCCD4             ; CCD4_SJI_OPERATING
        tccd[4:7] = index.BT06CBPX           ; CEB_ON_THE_POSX_AXIS 
        tccd[8:11] = index.BT07CBNX          ; CEB_ON_THE_NEGX_AXIS 
      endif else begin                       ; cant find any temps anywhere!
        print,'ERROR. no valid temperature information!'
        tccd=findgen(12)-9999999.              ; set to *really* bad temp value
      endelse
   endif else tccd = temps                   ; use the input temps array 
endif else begin                           ; use temperature tables
   tobs=anytim(date0)
   nint=n_elements(it0)
   tccd=fltarr(nint)
   ttab=anytim(time_tab)
   temp_tab0 = temp_tab                    ; copy temperature table
   ib=where(temp_tab lt -100,nb)           ; look for bad temperatures
   if nb ne 0 then temp_tab0[ib] = -9999999. ; set to *really* bad temp value
   for k=0,nint-1 do tccd[k] = $           ; interpolate with time shifts
       interpol(reform(temp_tab0[it0[k],*]),ttab+dt[k]*60.,tdate) 
endelse

;              estimate average seasonal temperature
week = anytim2week(date0)                                 ; week of obs
tccdav_fall=[-64.91,-64.42,-64.16,-65.04,0.41,1.12,31.26] ; avg for 09/18
case 1 of
  (week le 6 or week ge 46): tccdav=tccdav_fall -2.8     ; winter (-predict)
  (week ge 19 and week le 32): tccdav=tccdav_fall + 2.8  ; summer (-predict)
  else: tccdav=tccdav_fall                               ; spring/fall
endcase

ibad=where((tccd-tccdav[it0]) lt -20,nbad)        ; test for bad temperatures
if nbad ne 0 then tccd[ibad] = tccdav[it0[ibad]]  ; replace bad w/season avgs

;crate = 0.95                          ; tweak factor for rates
crate=1.03
ns=21                                  ; smoothing for ramp juncture

bin=nspec*nspat                        ; binning factor
levels=fltarr(3,4)                     ; setup output levels array (Added another row to split up ped. levels [J. Prchlik 2016/10/16])
x=findgen(2061)
xarr=x#(fltarr(528)+1.)                ; array of row #s (x) for non-pedestal
if ins eq 1 then begin                 ; setup ramp sizes
   imid=[868,868,2060-868,2060-868]       ; mid-point of main dark slope(1) ramp
   ibeg2=[1736,1736,0,0]                  ; begin point for dark slope2 ramp
   n2=2061-1736                           ; size of ramp2
   rs2 =1.                                ; ramp scale factor
endif else begin
   imid=[932,932,2060-932,2060-932]       ; mid-point of main dark slope(1) ramp
   ibeg2=[1864,1864,0,0]                  ; begin point for dark slope2 ramp
   n2=2061-1864                           ; size of ramp2
   rs2 =0.5                               ; ramp scale factor
endelse

id=it(0:3)                            ; index for dark current temperature
iped=it(4:7)                            ; index for pedestal temperature

if ins eq 1 then begin                 ; # spatial summing offset
   n2off=[[0,0,0,0],[3.23,0.89,4.38,0.98],[-.77,-2.69,-1.16,-4.02]]
   n2off=[[0,0,0,0],[3.25,0.91,4.42,1.01],[-.77,-2.69,-1.16,-4.02]] ; wtd ave
endif else begin
   n2off=[[0,0,0,0],[0.64,0.40,0.63,0.43],[-0.93,-.55,-1.51,0.16]] ; 
   n2off=[[0,0,0,0],[0.64,0.40,0.66,0.44],[-0.93,-.55,-1.51,0.16]] ; wtd ave
endelse


;iris_dark_trend_fix,index,ltoff        ;* compute long-term trends by port
;skip long term trend J. Prchlik (2016/10/21)
ltoff = fltarr(4)

sign1f = -1                            ;  slope1 sign for FUV
for k=0,3 do begin                     ; loop thru CCD read ports
                                       ; set scaling parameters by port
   cped=cp[*,k]                        ; note: k=0-3 = EFHG
   c0=cd[*,k]
   temp0=tccd[id[k]]
   tempped=tccd[iped[k]]
   cslope1=csl1[*,k]
   cslope2=csl2[*,k]
   imidk=imid[k]
   ibegk=ibeg2[k]
   ltoffk=ltoff[k]                                     ;* long-term trend offset
   n2offk=n2off[k,fix(nspat/2)]                        ;* spatial summing offset
   case 1 of  
      (k eq 0): begin                                    ;  port E
         dj0 = d0[0:2071,0:547]                             ; extract port 
         rate = crate*exp(poly(temp0,c0))*bin                ; dark rate (DN/s)
         ped = poly(tempped,cped) + poff[k] + ltoffk     ;* pedestal + L-T trend
         slope1 = poly(tint,cslope1) - poly(0.,cslope1)   ; main dark slope(1)
         slope1 = slope1*nspec                            ; scaling for slope 1
         sign1 = slope1/abs(slope1)                       ; get sign
         ramp1 = slope1*(xarr - imidk)                    ; adjust & make ramp1
         slope2 =  poly(tint,cslope2)                     ; main dark slope2
         slope2 = slope2*(sign1/sign1f)*bin               ; scaling for slope 2
         ramp2 = slope2*(xarr-ibegk)*rs2                      ; make ramp2
         ramp = ramp2*(xarr ge ibegk) + ramp1             ; assemble ramp
         ramp=smooth(ramp,ns,/edge_trunc)                ; smooth juncture
         dj0 = dj0 + ped                                  ; add pedestal 
         djx = dj0[0:2060,20:*]                           ; extract data part
         djx = djx + ramp + n2offk                        ; add ramp adjustment 
         djx = djx + rate*tint                            ; add dark current 
         d0[0,0] = dj0                                ; input new pedestal 
         levels[0,k] = poly(tempped,cped)                 ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         levels[2,k] = poff[k]                            ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)

         d0[0,20] = djx                               ; input new data 
         levels[1,k] = rate*tint + n2offk        ; put <dark current> in levels
      end                                               ; with corrections
      (k eq 1): begin                                    ;  port F
         dj0 = d0[0:2071,548:*]                             ; extract port
         rate = crate*exp(poly(temp0,c0))*bin                ; dark rate (DN/s)
         ped = poly(tempped,cped) + poff[k] + ltoffk     ;* pedestal + L-T trend
         slope1 = poly(tint,cslope1) - poly(0.,cslope1)   ; main dark slope(1)
         slope1 = slope1*nspec                            ; scaling for slope 1
         sign1 = slope1/abs(slope1)                       ; get sign
         ramp1 = slope1*(xarr - imidk)                    ; adjust & make ramp1
         slope2 =  poly(tint,cslope2)                     ; main dark slope2
         slope2 = slope2*(sign1/sign1f)*bin               ; scaling for slope 2
         ramp2 = slope2*(xarr-ibegk)*rs2                      ; make ramp2
         ramp = ramp2*(xarr ge ibegk) + ramp1             ; assemble ramp
         ramp=smooth(ramp,ns,/edge_trunc)                ; smooth juncture
         dj0 = dj0 + ped                                  ; add pedestal 
         djx = dj0[0:2060,0:527]                          ; extract data part
         djx = djx + ramp + n2offk                        ; add ramp adjustment 
         djx = djx + rate*tint                            ; add dark current 
         d0[0,548] = dj0                                  ; input new pedestal 
;         levels[0,k] = ped                            ; put pedestal in levels
         levels[0,k] = poly(tempped,cped)                 ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         levels[2,k] = poff[k]                            ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         d0[0,548] = djx                               ; input new data 
         levels[1,k] = rate*tint + n2offk        ; put <dark current> in levels
      end                                               ; with corrections
      (k eq 2): begin                                    ;  port H =c
         dj0=d0[2072:*,0:547]                               ; extract port
         rate = crate*exp(poly(temp0,c0))*bin                ; dark rate (DN/s)
         ped = poly(tempped,cped) + poff[k] + ltoffk     ;* pedestal + L-T trend
         slope1 = poly(tint,cslope1)                      ; main dark slope(1)
         slope1 = slope1*nspec                            ; scaling for slope 1
         sign1 = slope1/abs(slope1)                       ; get sign
         ramp1 = slope1*(xarr - imidk)                    ; adjust & make ramp1
         slope2 =  poly(tint,cslope2)                     ; main dark slope2
         slope2 = slope2*(sign1/sign1f)*bin               ; scaling for slope 2
         ramp2 = slope2*(xarr-n2)*rs2                        ; make ramp2
         ramp = ramp2*(xarr lt n2) + ramp1             ; assemble ramp
         ramp=smooth(ramp,ns,/edge_trunc)                ; smooth juncture
         dj0 = dj0 + ped                                  ; add pedestal 
         djx = dj0[0:2060,20:*]                           ; extract data part
         djx = djx + ramp + n2offk                        ; add ramp adjustment 
         djx = djx + rate*tint                            ; add dark current 
         d0[2072,0] = dj0                                ; input new pedestal 
;         levels[0,k] = ped                            ; put pedestal in levels
         levels[0,k] = poly(tempped,cped)                 ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         levels[2,k] = poff[k]                            ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         d0[2083,20] = djx                               ; input new data 
         levels[1,k] = rate*tint + n2offk        ; put <dark current> in levels
      end                                               ; with corrections
      else: begin                                    ;  port G = d
         dj0=d0[2072:*,548:*]                               ; extract port
         rate = crate*exp(poly(temp0,c0))*bin                ; dark rate (DN/s)
         ped = poly(tempped,cped)  + poff[k] + ltoffk    ;* pedestal + L-T trend
         slope1 = poly(tint,cslope1)                      ; main dark slope(1)
         slope1 = slope1*nspec                            ; scaling for slope 1
         sign1 = slope1/abs(slope1)                       ; get sign
         ramp1 = slope1*(xarr - imidk)                    ; adjust & make ramp1
         slope2 =  poly(tint,cslope2)                     ; main dark slope2
         slope2 = slope2*(sign1/sign1f)*bin               ; scaling for slope 2
         ramp2 = slope2*(xarr-n2)*rs2                      ; make ramp2
         ramp = ramp2*(xarr lt n2) + ramp1                ; assemble ramp
         ramp=smooth(ramp,ns,/edge_trunc)                ; smooth juncture
         dj0 = dj0 + ped                                  ; add pedestal 
         djx = dj0[0:2060,0:527]                           ; extract data part
         djx = djx + ramp + n2offk                        ; add ramp adjustment 
         djx = djx + rate*tint                            ; add dark current 
         d0[2072,548] = dj0                                ; input new pedestal 
;         levels[0,k] = ped                            ; put pedestal in levels
         levels[0,k] = poly(tempped,cped)                 ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         levels[2,k] = poff[k]                            ; put pedestal in levels (Split 2016/10/28 J. Prchlik to find cause of long term trend)
         d0[2083,548] = djx                               ; input new data 
         levels[1,k] = rate*tint + n2offk        ; put <dark current> in levels
      end                                               ; with corrections
   endcase
endfor

if ins eq 0 then begin
   if index.instrume eq 'SJI' then d0= d0[0:2071,*]
   if index.instrume eq 'NUV' and index.img_path eq 'NUV' then d0= d0[2072:*,*]
endif


dsize = size(d0)
if bin ne 1 then dark = rebin(d0, dsize[1]/nspec, dsize[2]/nspat) $
  else dark = d0                                        ; rebin as needed


temps = tccd

;  b   d   F=fuv1 sji   G=fuv2 nuv   
;  a   c   E=fuv1 sji   H=fuv2 nuv



return                                                  
end
;
;
;


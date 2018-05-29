
;pro iris_dark_trend_fix, index, offsets,  progver = progver
pro iris_dark_trend_fix, obstime, offsets,type,  progver = progver

; ============================================================================
;+
;
; PROJECT:
;
;     IRIS
;
; NAME:
;
;     IRIS_DARK_TREND_FIX
;
; CATEGORY:
;
;       Data calibration
;
; PURPOSE:
;
;       Calculates offsets for long-term trends in dark levels based on BLS
;       measurements and measured dark levels;  meant to be used within 
;       IRIS_MAKE_DARK
;
; CALLING SEQUENCE:
;
; INPUTS:
;
;         INDEX:  [mandatory] IRIS type index structure of the data array
;                 for which you want a dark generated (a single index).
;
;
;
; OUTPUTS:
;
;       OFFSETS:  [mandatory] Set of offsets to correct for long-term trends
;                 for 4 CCD read ports
;                 (either FUV 1-4, or SJI/NUV 1-4, depending on INDEX)
;   
;                 values of offsets should be subtracted from the values
;                 calculated for each CCD port in IRIS_MAKE_DARK
;
;
;  EXAMPLE:
;
;               iris_dark_trend_fix index, offsets
;
;
; OPTIONAL INPUT KEYWORD PARAMETERS:
;                 None
;
; OPTIONAL OUTPUT KEYWORD PARAMETERS:
;         PROGVER:   String describing the version of this routine that was run
;
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
progver = 'v2014.Sep.12' ;--- (SSaar) Written.
progver = 'v2014.Sep.23' ;--- (SSaar) V2 with double sine model.
progver = 'v2014.Sep.28' ;--- (SSaar) V3 with double sine model; cyclic amp var.
progver = 'v2014.Nov.15' ;--- (SSaar) V3 with updated parameters #1 
progver = 'v2015.Apr.13' ;--- (SSaar) V3.1 with updated parameters #2, split
;                                       secondary trend phase shift
progver = 'v2015.Sep.30' ;--- (SSaar) V4 with new double sine model + linear
;                                       trend, P2=P1/2 
progver = 'v2016.Jan.10' ;--- (SSaar) V5 update of double sine model + linear
;                                       trend, P2=P1/2, data thru 11/15 
progver = 'v2016.May.13' ;--- (SSaar) V6 update of double sine model + quad 
;                                       trend, P2=P1/2, data thru 05/16 
progver = 'v2016.Oct.07' ;--- (SSaar) V7 update of 2 sine model + shifted quad
;                                       trend, P2=P1/2, data thru 09/16
progver = 'v2016.Nov.14' ;--- (SSaar) V8 same as V7, fixed indexing bug
;
progver = 'v2016.Dec.28' ;--- (SSaar) V9 update (NUV only) of double sine model
;                                       +quad trend, P2=P1/2, data thru 12/16
progver = 'v2017.Apr.07' ;--- (SSaar) V10 update of double sine model
;                                       +quad trend, P2=P1/2, data thru 03/17
progver = 'v2017.Jun.06' ;--- (SSaar,JPrchlik) V11 update of double sine model
;                                       +quad trend, P2=P1/2, data thru 05/17
progver = 'v2017.Oct.16' ;--- (SSaar,JPrchlik) V12 update of double sine model
;                                       +quad trend, P2=P1/2, data thru 10/17
progver = 'v2018.May.29' ;--- (SSaar,JPrchlik) V13 update of double sine model
;                                       +quad trend, P2=P1/2, data thru 05/18
;                                       Add parameter to flatten quad and linear
;                                       trends after August 2017
;
;
;-
; ============================================================================



;ins = index.instrume ne 'FUV'
ins = type ne 'FUV'

k=indgen(4)  + ins*4                          


fuv1=[ 0.19862  , 0.07801  ,  3.2101e+07   , 0.47127  , 0.14926  ,  2.851681516e-08   ,$
       5.610333043e-16   , -0.59788 ,   0.38371]
fuv2=[ 0.28535  , 0.20777  ,  3.1671e+07   , 0.38135  , 0.90796  ,  2.883263417e-08   ,$
       3.976993552e-16   , -0.57493 ,   0.48750]
fuv3=[ 1.60381  , 1.64299  ,  3.1620e+07   , 0.33483  , 0.88216  ,  2.834048526e-08   ,$
       1.190318064e-15   , -0.72855 ,   0.25935]
fuv4=[ 0.33159  , 0.19315  ,  3.1641e+07   , 0.42014  , 0.94635  ,  1.966054402e-08   ,$
       9.522024659e-16   , -0.66065 ,   0.26030]
nuv1=[ 0.58898  , 0.56991  ,  3.1594e+07   , 0.31556  , -0.10659 ,  4.657181305e-09   ,$
       2.025746662e-16   , -0.20046 ,   0.26542]
nuv2=[ 0.72959  , 0.70146  ,  3.1688e+07   , 0.32213  , 0.90370  ,  3.479937632e-09   ,$
       2.754279272e-16   , -0.21316 ,   0.22897]
nuv3=[ 0.26941  , 0.25662  ,  3.1653e+07   , 0.33193  , 0.90995  ,  9.954674645e-09   ,$
       3.174683491e-16   , -0.12158 ,   0.55768]
nuv4=[ 0.45264  , 0.46882  ,  3.1656e+07   , 0.33149  , 0.90929  ,  8.590269637e-09   ,$
       3.136282184e-16   , -0.25561 ,   0.41518]


if ins eq 0 then begin                     ; if FUV, load up variables
   amp1=[fuv1(0),fuv2(0),fuv3(0),fuv4(0)]   ; amp of variation with period p1
   amp2=[fuv1(1),fuv2(1),fuv3(1),fuv4(1)]  ; amp of variation with period p1/2
   p1=[fuv1(2),fuv2(2),fuv3(2),fuv4(2)]    ; period of main variation [s]
   phi1=[fuv1(3),fuv2(3),fuv3(3),fuv4(3)]  ; phase offset for p=p1 variation
   phi2=[fuv1(4),fuv2(4),fuv3(4),fuv4(4)]  ; phase offset for p=p1/2 variation
   trend=[fuv1(5),fuv2(5),fuv3(5),fuv4(5)] ; linear long-term trend
   quad=[fuv1(6),fuv2(6),fuv3(6),fuv4(6)]  ;  quadratic term
   off=[fuv1(7),fuv2(7),fuv3(7),fuv4(7)]   ; offset constant
   scl=[fuv1(8),fuv2(8),fuv3(8),fuv4(8)]   ; Rescaling trend after given time frame 2018/05/29 J. Prchlik
   dtq0 = 5e7                               ; start time, quad term
   tq_end = 1.295e8                               ; end time, quad term
endif else begin                          ; if NUV/SJI
   amp1=[nuv1(0),nuv2(0),nuv3(0),nuv4(0)]
   amp2=[nuv1(1),nuv2(1),nuv3(1),nuv4(1)]
   p1=[nuv1(2),nuv2(2),nuv3(2),nuv4(2)]
   phi1=[nuv1(3),nuv2(3),nuv3(3),nuv4(3)]
   phi2=[nuv1(4),nuv2(4),nuv3(4),nuv4(4)]
   trend=[nuv1(5),nuv2(5),nuv3(5),nuv4(5)]
   quad=[nuv1(6),nuv2(6),nuv3(6),nuv4(6)]
   off=[nuv1(7),nuv2(7),nuv3(7),nuv4(7)]
   scl=[nuv1(8),nuv2(8),nuv3(8),nuv4(8)]   ; Rescaling trend after given time frame 2018/05/29 J. Prchlik
   dtq0 = 7e7                               ; start time, quad term
   tq_end = 1.295e8                               ; end time, quad term
endelse



t0=[1090654728d0,1089963933d0,1090041516d0,1090041516d0,1090037115d0, $ 
     1090037115d0,1090037185d0,1090037185d0]     ; zero epoch


;t=anytim(index.date_obs)
t=anytim(obstime)

c=2*!pi



dt0 = t - t0[k]

;Adjust quadratic and linear time after date when quadratic term turns over 2018/05/29 J. Prchlik
dtq = dt0 > dtq0 ;Removed quadtratic end time 2018/05/29 J. Prchlik
dtq = dtq - dtq0                   ; timeline for quad term, for dt0>dtq0

;Get where times are above the qaudratic and linear terms turn over 2018/05/29 J. Prchlik
adj = -(dt0 gt tq_end)*(1.0-scl)+1
;Change offset to it is continous across boundary of term flatterning 2018/05/29 J. Prchlik
;Solve of boundary condition
toff = (1.0-scl)*(quad*(tq_end-dtq0)^2+trend*tq_end)+off
;Get difference between curved and flat boundary
doff = toff-off
;apply boundary when time exceeds tq_end
off = off+(dt0 gt tq_end)*doff

; add it together: 
;  A1 *sin(t/p +phi1) + A2 *sin (2*t/p +phi2) + B*t + C*(t>tq0<tq_end)^2   


offsets = amp1 *sin(c*(dt0/p1 + phi1)) +  $
           amp2 *sin(c*(dt0/(p1/2) + phi2)) +  $
           trend*adj*dt0  + adj*quad*dtq^2 + off 


;if max(dt0) gt tq_end then stop ;else print,off
return
end
;
;
;

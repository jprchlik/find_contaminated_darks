
;pro iris_dark_trend_fix, index, offsets,  progver = progver
pro iris_dark_trend_fix, obstime, offsets, type, progver = progver
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
progver = 'v2017.Dec.14' ;--- (SSaar,JPrchlik) V13 update of double sine model
;                                       +quad trend (now with stop time for
;                                        FUV), P2=P1/2, data thru 11/17
progver = 'v2018.Feb.02' ;--- (SSaar,JPrchlik) V14 update of double sine model
;                                       +quad trend (now with stop time),
;                                        P2=P1/2, data thru 01/18
progver = 'v2018.May.29' ;--- (SSaar,JPrchlik) V15 update of double sine model
;                                       +quad trend, P2=P1/2, data thru 05/18
;                                      linear+quad trend now reduced after 8/17
;
;
;-
; ============================================================================



;ins = index.instrume ne 'FUV'
ins = type ne 'FUV'

k=indgen(4)  + ins*4                          


fuv1=[ 0.19922  , 0.07698  ,  3.2020e+07   , 0.46748  , 0.13289  ,  2.828782947e-08   ,$
       5.683836798e-16   , -0.59034 ,   0.357]
fuv2=[ 0.28201  , 0.21098  ,  3.1610e+07   , 0.38922  , 0.89576  ,  2.786122108e-08   ,$
       4.265646236e-16   , -0.54181 ,   0.357]
fuv3=[ 1.63208  , 1.63397  ,  3.1609e+07   , 0.32927  , 0.88294  ,  3.092388058e-08   ,$
       1.124857033e-15   , -0.81379 ,   0.357]
fuv4=[ 0.32909  , 0.18118  ,  3.1669e+07   , 0.41185  , 0.95284  ,  2.139613246e-08   ,$
       9.060289897e-16   , -0.73099 ,   0.357]
nuv1=[ 0.59161  , 0.57037  ,  3.1602e+07   , 0.31526  , -0.10472 ,  4.800729711e-09   ,$
       1.926945561e-16   , -0.20605 ,   0.357]
nuv2=[ 0.73379  , 0.70328  ,  3.1698e+07   , 0.32155  , 0.90637  ,  3.784201739e-09   ,$
       2.559618399e-16   , -0.22506 ,   0.357]
nuv3=[ 0.26589  , 0.25504  ,  3.1612e+07   , 0.33407  , 0.89746  ,  9.345864913e-09   ,$
       3.545814274e-16   , -0.09758 ,   0.357]
nuv4=[ 0.45101  , 0.46819  ,  3.1648e+07   , 0.33230  , 0.90779  ,  8.445645868e-09   ,$
       3.239736069e-16   , -0.25022 ,   0.357]


if ins eq 0 then begin                     ; if FUV, load up variables
   amp1=[fuv1(0),fuv2(0),fuv3(0),fuv4(0)]   ; amp of variation with period p1
   amp2=[fuv1(1),fuv2(1),fuv3(1),fuv4(1)]  ; amp of variation with period p1/2
   p1=[fuv1(2),fuv2(2),fuv3(2),fuv4(2)]    ; period of main variation [s]
   phi1=[fuv1(3),fuv2(3),fuv3(3),fuv4(3)]  ; phase offset for p=p1 variation
   phi2=[fuv1(4),fuv2(4),fuv3(4),fuv4(4)]  ; phase offset for p=p1/2 variation
   trend=[fuv1(5),fuv2(5),fuv3(5),fuv4(5)] ; linear long-term trend
   quad=[fuv1(6),fuv2(6),fuv3(6),fuv4(6)]  ;  quadratic term
   off=[fuv1(7),fuv2(7),fuv3(7),fuv4(7)]   ; offset constant
   scl=[fuv1(8),fuv2(8),fuv3(8),fuv4(8)]   ; Rescaling trend after given time 
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
   scl=[nuv1(8),nuv2(8),nuv3(8),nuv4(8)]   ; Rescaling trend after given time 
   dtq0 = 7e7                               ; start time, quad term
   tq_end = 1.295e8                               ; end time, quad term
endelse



t0=[1090654728d0,1089963933d0,1090041516d0,1090041516d0,1090037115d0, $ 
     1090037115d0,1090037185d0,1090037185d0]     ; zero epoch


;t=anytim(index.date_obs)
t=anytim(obstime)

c=2*!pi



dt0 = t - t0[k]

dtq = dt0 > dtq0                   ; Removed quadratic end time 
dtq = dtq - dtq0                   ; timeline for quad term, for dt0>dtq0

tred = (dt0 gt tq_end)             ; times > when lin+quad trend are reduced 
                                   ;  (tq_end is now where trends are reduced)
adj = 1.0 - tred*(1.0-scl)         ; rescale at trend change boundary: 
                                   ;      1->scl
; Change offset across boundary so trend is continuous 
toff = (1.0-scl)*(quad*(tq_end-dtq0)^2+trend*tq_end)+off ; new boundary value 
off = off*(tred ne 1) + toff*tred  ; apply new boundary when t>tq_end

; add it together: 
;  A1 *sin(t/p +phi1) + A2 *sin (2*t/p +phi2) + B*t + C*(t>tq0)^2   


offsets = amp1 *sin(c*(dt0/p1 + phi1)) +  $
           amp2 *sin(c*(dt0/(p1/2) + phi2)) +  $
           trend*adj*dt0  + adj*quad*dtq^2 + off 


return
end
;
;
;

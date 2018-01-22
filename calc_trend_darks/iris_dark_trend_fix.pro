
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
;
;
;
;-
; ============================================================================



;ins = index.instrume ne 'FUV'
ins = type ne 'FUV'

k=indgen(4)  + ins*4                          


;fuv1=[  0.189662 ,  0.0178533 , 3.15070e+07 ,   0.445460  ,   0.104290 ,  $
;  2.925e-08 , 5.473e-16 ,   -0.598880 ]
;fuv2= [ 0.26720  , 0.20045  ,  3.1565e+07   , 0.37567  , 0.89111  ,  $ 
;  2.868e-08   ,  4.003e-16   , -0.56086 ]
;fuv3= [1.48098   ,   1.45770 , 3.15160e+07  ,   0.333684  ,   0.872832 , $ 
;  2.856e-08 , 1.151e-15 ,   -0.582085 ]
;fuv4=[0.310112  ,   0.132660,  3.13800e+07   , 0.418674    , 0.951970  , $
;  1.8805e-08 , 9.618e-16   , -0.612558]
;nuv1=[ 0.55083  , 0.54792  ,  3.1788e+07   , 0.32558  , -0.08227 ,  $ 
;  3.116e-09   ,  2.823e-16   , -0.13231 ]
;nuv2=[ 0.71724  , 0.69646  ,  3.1847e+07   , 0.32991  , 0.92275  ,  $ 
;  1.788e-09   ,  3.599e-16   , -0.15109 ]
;nuv3=[ 0.26202  , 0.25259  ,  3.1702e+07   , 0.32890  , 0.91326  ,  $ 
;  9.521e-09   ,  3.424e-16   , -0.09947 ]
;nuv4=[ 0.41113  , 0.45427  ,  3.1648e+07   , 0.31998  , 0.90299  ,  $ 
;  6.874e-09   ,  3.887e-16   , -0.16182 ]

;End quadratic term parameters 2017/12/07
fuv1 =[ 0.16212, 0.02622,  3.1507e+07, 0.41595, 0.09385,  2.81946e-08, $
   5.70504e-16, -0.56934 ]
fuv2 =[ 0.25704, 0.19422,  3.1568e+07, 0.37571, 0.89102,  2.83259e-08,  $
   4.10837e-16, -0.54180 ]
fuv3 =[ 1.46459, 1.62793,  3.1519e+07, 0.33365, 0.87274,  2.61867e-08,  $
   1.21900e-15, -0.60398 ]
fuv4 =[ 0.27947, 0.14585,  3.1383e+07, 0.39938, 0.90869,  1.88069e-08,  $
   9.61989e-16, -0.59357 ]
nuv1=[ 0.55495, 0.53251,  3.1782e+07, 0.32965, -0.07967,  3.99582e-09, $
   2.29718e-16, -0.16966 ]
nuv2=[ 0.73259, 0.68243,  3.1841e+07, 0.33437, 0.92937,  3.27857e-09,  $
   2.74372e-16, -0.21646 ]
nuv3=[ 0.26427, 0.24439,  3.1696e+07, 0.33597, 0.91779,  1.00492e-08,  $
   3.09861e-16, -0.12297 ]
nuv4=[ 0.41707, 0.44189,  3.1642e+07, 0.32680, 0.90548,  7.94323e-09,  $
   3.28484e-16, -0.21366 ]



if ins eq 0 then begin                     ; if FUV, load up variables
   amp1=[fuv1(0),fuv2(0),fuv3(0),fuv4(0)]   ; amp of variation with period p1
   amp2=[fuv1(1),fuv2(1),fuv3(1),fuv4(1)]  ; amp of variation with period p1/2
   p1=[fuv1(2),fuv2(2),fuv3(2),fuv4(2)]    ; period of main variation [s]
   phi1=[fuv1(3),fuv2(3),fuv3(3),fuv4(3)]  ; phase offset for p=p1 variation
   phi2=[fuv1(4),fuv2(4),fuv3(4),fuv4(4)]  ; phase offset for p=p1/2 variation
   trend=[fuv1(5),fuv2(5),fuv3(5),fuv4(5)] ; linear long-term trend
   quad=[fuv1(6),fuv2(6),fuv3(6),fuv4(6)]  ;  quadratic term
   off=[fuv1(7),fuv2(7),fuv3(7),fuv4(7)]   ; offset constant
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
   dtq0 = 7e7
   tq_end = 7e10                              ; start tim
endelse



t0=[1090654728d0,1089963933d0,1090041516d0,1090041516d0,1090037115d0, $ 
     1090037115d0,1090037185d0,1090037185d0]     ; zero epoch


;t=anytim(index.date_obs)
t=anytim(obstime)

c=2*!pi



dt0 = t - t0[k]
dtq = dt0 > dtq0 <tq_end    
dtq = dtq - dtq0                   ; timeline for quad term, for dt0>dtq0


; add it together: 
;  A1 *sin(t/p +phi1) + A2 *sin (2*t/p +phi2) + B*t + C*((t-tq)>0)^2   


offsets = amp1 *sin(c*(dt0/p1 + phi1)) +  $
           amp2 *sin(c*(dt0/(p1/2) + phi2)) +  $
           trend*dt0  + quad*dtq^2 + off 


return
end
;
;
;

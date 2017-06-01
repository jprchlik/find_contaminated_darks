
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
;
;
;
;-
; ============================================================================



;ins = index.instrume ne 'FUV'
ins = type ne 'FUV'

k=indgen(4)  + ins*4                          


fuv1=[0.163 ,  0.0800 ,3.18e+07 ,   0.397  ,  0.259, 2.25e-08, $
  7.60e-16  , -0.3232  ]
fuv2=[0.257 ,   0.230 ,3.11100e+07 ,   0.355  ,  0.890, 2.81e-08, $
  3.47e-16  , -0.4723 ]
fuv3=[1.26100  ,   1.43500 ,3.16500e+07  ,  0.332   ,-0.107 ,3.20e-08, $
  9.57e-16  , -0.6785 ]
fuv4=[ 0.219,    0.175, 3.15e+07,    0.385 ,   0.95500,  1.507e-08, $
  1.066e-15  , -0.4582]

nuv1=[0.419 ,  0.4955,  3.135e+07,   0.2756,   -0.161,  2.893e-09, $
    6.71e-17,  -0.0459519 ]
nuv2=[0.526,  0.615,  3.125e+07,  0.270,  0.824, -5.479e-12, $
    1.345e-16,    0.0387826  ]
nuv3=[  0.217,     0.233,   3.208e+07,  0.370,  0.983,  8.427e-09,  $
    3.004e-16,   -0.0533 ]
nuv4=[ 0.362,   0.437,   3.144e+07,   0.3027,  0.859,  4.73155e-09, $
    3.67756e-16,   -0.04390  ]


fuv1=[ 0.16640  , 0.07357  ,  2.9806e+07   , 0.26320  , -0.49164 ,  -1.797731889e-08  ,  5.288649388e-16   , 0.33515  ]
fuv2=[ 0.31796  , 0.19112  ,  3.1781e+07   , 0.40323  , 0.90159  ,  7.139288705e-09   ,  2.904046708e-16   , -0.25856 ]
fuv3=[ 1.68766  , 1.65641  ,  3.1610e+07   , 0.33213  , -0.12565 ,  -4.631262900e-08  ,  9.397098665e-16   , 0.51133  ]
fuv4=[ 0.33760  , 0.15481  ,  3.1172e+07   , 0.36496  , 0.83378  ,  -5.308451458e-08  ,  8.436796768e-16   , 0.70454  ]
nuv1=[ 0.56669  , 0.54388  ,  3.1812e+07   , 0.33569  , -0.08140 ,  -6.793888978e-09  ,  1.138799371e-16   , 0.02638  ]
nuv2=[ 0.74289  , 0.69508  ,  3.1868e+07   , 0.34009  , 0.92298  ,  -1.182903493e-08  ,  1.537841815e-16   , 0.07035  ]
nuv3=[ 0.28979  , 0.25669  ,  3.1675e+07   , 0.34083  , 0.90104  ,  -3.346991254e-09  ,  1.445607846e-16   , 0.11399  ]
nuv4=[ 0.43505  , 0.44374  ,  3.1768e+07   , 0.34617  , 0.91770  ,  -5.837637926e-09  ,  1.500868586e-16   , 0.03091  ]



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
endelse



t0=[1090654728d0,1089963933d0,1090041516d0,1090041516d0,1090037115d0, $ 
     1090037115d0,1090037185d0,1090037185d0]     ; zero epoch


;t=anytim(index.date_obs)
t=anytim(obstime)

c=2*!pi



dt0 = t - t0[k]
;dtq = (dt0 - dtq0) > 0.     ; timeline for quad term, not present dt0<dtq0


; add it together: 
;  A1 *sin(t/p +phi1) + A2 *sin (2*t/p +phi2) + B*t + C*((t-tq)>0)^2   


offsets = amp1 *sin(c*(dt0/p1 + phi1)) +  $
           amp2 *sin(c*(dt0/(p1/2) + phi2)) +  $
           trend*dt0  + quad*dt0^2 + off 


return
end
;
;
;

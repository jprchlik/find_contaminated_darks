
pro iris_dark_trend_fix, obstime, offsets, type,  progver = progver

; ============================================================================
;+
;
; PROJECT:
;
;     IRIS
;
; NAME:
;
;     TREND_FIX
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
;               trend_fitx index, offsets
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
;
;
;-
; ============================================================================



;ins = index.instrume ne 'FUV'
ins = type ne 'FUV'

k=indgen(4)  + ins*4                          


;From failed recal
;fuv1=[0.140000,   0.0520000, 3.18000e+07,    0.405000,    0.183000, 2.66780e-08,$
;      6.29336e-16,   -0.515554];Tot. sig = 0.12373981
;fuv2=[0.191000,    0.174996, 3.11100e+07,    0.275993,    0.790000, 2.84486e-08,$
;      3.12458e-16,   -0.493009];Tot. sig = 0.18320804
;fuv3=[1.13500,     1.44600, 3.16500e+07,    0.317000,   -0.119000, 3.74216e-08,$
;      7.79973e-16,   -0.805986];Tot. sig = 0.464
;fuv4=[0.177000,    0.153000, 3.15000e+07,    0.351000,    0.931000, 1.66521e-08,$
;      9.49940e-16,   -0.481972];Tot. sig = 0.14461537


;commented for possible recal
fuv1=[0.163 ,  0.0800 ,3.18e+07 ,   0.397  ,  0.259, 2.25e-08, $
  7.60e-16  , -0.340043]
fuv2=[0.257 ,   0.230 ,3.11100e+07 ,   0.355  ,  0.890, 2.81e-08, $
  3.47e-16  , -0.475306]
fuv3=[1.26100  ,   1.43500 ,3.16500e+07  ,  0.332   ,-0.107 ,3.20e-08, $
  9.57e-16  , -0.658716 ]
fuv4=[ 0.219,    0.175, 3.15e+07,    0.385 ,   0.95500,  1.41e-08, $
  1.03e-15  , -0.395319]


;From failed recal
;nuv1=[0.394814,    0.479234, 3.13500e+07,    0.273128,   -0.161240, 4.89754e-09,$
;      -1.54907e-20,   -0.110502] ;Tot. sig = 0.16015262
;nuv2=[0.493802,    0.588224, 3.12500e+07,    0.273924,    0.826750,     0.00000,$
;       1.59483e-16,   0.0356029] ;Tot. sig= 0.19863121
;nuv3=[0.203975,    0.216075, 3.20800e+07,    0.313000,    0.936000, 1.17735e-08,$
;      -9.88741e-22,   -0.148673]; Tot. sig= 0.097321901
;nuv4=[0.306000,    0.393000, 3.14400e+07,    0.286000,    0.848000, 6.27228e-09,$
;       1.34225e-16,  -0.0797418]; Tot. sig= 0.12603566

;Commented for possible recal
nuv1=[0.409  ,  0.485 ,3.13500e+07  ,  0.297  , -0.147 ,7.32e-10, $
  4.90e-16 ,  0.0130799 ]
nuv2=[0.520  ,  0.605 ,3.12500e+07  ,  0.290  ,  0.838,-9.01e-10, $
  6.09400e-16 ,  0.0438169 ]
nuv3=[ 0.194 ,  0.210, 3.20800e+07 ,   0.340 ,   0.951, 1.00e-08, $
  2.56e-16 , -0.0926976]
nuv4=[ 0.320 ,  0.408, 3.14400e+07 ,   0.317 ,   0.860 ,6.66e-09, $
 1.11450e-15 ,  -0.104511 ]



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
dtq = (dt0 - dtq0) > 0.     ; timeline for quad term, not present dt0<dtq0


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

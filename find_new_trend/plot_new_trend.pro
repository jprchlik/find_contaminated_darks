pro plot_new_trend
;Program fits and plots new dark model trend to 2014 data
;Then applies model to 2015 and 2016

loadct,12
restore,'../calc_trend_darks/alldark_ave_sig.sav'

resolve_routine,'get_binned_iris_dark_trend',/COMPILE_FULL_FILE
;fname = 'alldark_ave_sig_no_dark_model.sav'
;restore,fname

type = ['NUV','FUV']
ports = ['port1','port2','port3','port4']
labels = ['FUV1','FUV2','NUV','SJI','CEB_POSX1', 'CEB_POSX2', 'CEB_POSX3', 'CEB_POSX4', 'CEB_NEGX1', 'CEB_NEGX2', 'CEB_NEGX3', 'CEB_NEGX4']
labels = ['ITF1CCD1','ITF2CCD2','ITNUCCD3','ITSJCCD4','BT06CBPX','BT07CBNX','BT10HOPA','BT17SMAP','IT01PMRF','IT03PMRA','IT04TELF','IT12HOPA','IT13FRA']
;labels = ['ped1','ped2']
;labels = ['Temp Poly','Dark Current','Pedestal Off']
syms = [4,5,6,7]
color= [0,100,120,200]
;color = bindgen(n_elements(labels)-1)/n_elements(labels)*255

;create TIME array
;time = dblarr(n_elements(timeou))
normal = JULDAY(1,1,2012,0,0,0)
;for i=0,n_elements(timeou)-1 do begin
;
;     year  = fix(strmid(timeou[i],0,4))
;     month = fix(strmid(timeou[i],5,2))
;     day   = fix(strmid(timeou[i],8,2))
;     hour  = fix(strmid(timeou[i],11,2))
;     min   = fix(strmid(timeou[i],14,2))
;     sec   = fix(strmid(timeou[i],17,2))
;     time[i] = JULDAY(month,day,year,hour,min,sec)-normal
;endfor
string_to_time,timeou,time ; move JULDAY conversion to a function

time = time*24.*3600. ;Convert JULDAY to seconds


;get shape of avepix array
aveshape = size(avepix)

;create newly corrected CCD out values
newavepix = fltarr(aveshape[1],aveshape[2])

print,size(otemps)
;get new temperatures 
find_new_temps,timeou,otemps

;change temperature to K 
so = size(otemps)

print,so
;for j=0,so[1]-1 do print,median(otemps[j,*]),max(otemps[j,*]),min(otemps[j,*])


otemps = otemps+273.


;level = alog10(olevel)

fitpoly = fltarr(8,2)

for k=0,n_elements(type)-1 do begin

    ccdtyp = where(strmatch(basicf,type[k]+'*',/FOLD_CASE) EQ 1)
    ntemps = size(otemps)
    ntemps = ntemps[1]

    nlevls = size(olevel)
    nlevls = nlevls[1]

;Start and end time for fitting (To be predictive use just 2014)
    stime = (JULDAY(1,1,2014,0,0,0) -normal)*24.*3600.
    etime = (JULDAY(1,1,2015,0,0,0) -normal)*24.*3600.
;2015
    stime5 = (JULDAY(1,1,2015,0,0,0) -normal)*24.*3600.
    etime5 = (JULDAY(1,1,2016,0,0,0) -normal)*24.*3600.

;2016
    stime6 = (JULDAY(1,1,2016,0,0,0) -normal)*24.*3600.
    etime6 = (JULDAY(1,1,2017,0,0,0) -normal)*24.*3600.



; New time plots
  

;fit the most relavent temperatures
    for i=0,n_elements(labels)-1 do begin 
        xlim = [-75.,-52.]+273.
        xlim = [200.,400.]

        case labels[i] of 
            'BT06CBPX': xlim=[271.,276.]
            'BT07CBNX': xlim=[271.,276.]
            'BT10HOPA': xlim=[360.,372.]
            'BT17SMAP': xlim=[298.,308.]
            'IT01PMRF': xlim=[300.,320.]
            'IT03PMRA': xlim=[300.,320.]
            'IT04TELF': xlim=[290.,310.]
            'IT12HOPA': xlim=[330.,370.]
            'IT13FRA' : xlim=[290.,310.]
            'ITF1CCD1': xlim=[206.,218.]
            'ITF2CCD2': xlim=[206.,218.]
            'ITNUCCD3': xlim=[206.,218.]
            'ITSJCCD4': xlim=[206.,218.]
        endcase
        
        writeplot=0
        if type[k] eq 'NUV' then ylim = [98.,104.] else ylim = [93.,105.]

;UNCOMMENT FOR CCD TEMP FIT FIRST
        if i ge 4 then ylim=ylim-100.
        if i ge 4 then offset = 0. else offset = 0.
        if i le 3 then ylab = 'Average Dark Value ' else ylab='Average Dark Offset (Dark-New Model) '

;UNCOMMENT FOR CEB FIT FIRST
;        if labels[i] ne 'BT06CBPX' then ylim=ylim-100.
;        if labels[i] ne 'BT06CBPX' then offset = 0. else offset = 0.
;        if labels[i] ne 'BT06CBPX' then ylab = 'Average Dark Value ' else ylab='Average Dark Offset (Dark-New Model) '

;store poly fits
        plot,[0,0],[0,0],psym=0,linestyle=2,title=type[k],ytitle=ylab+'[ADU]',$
            xtitle=labels[i]+' Temperature [K]',xrange=xlim, $ ;yrange=[min(avepix[*,ccdtyp]),max(avepix[*,ccdtyp])],$
            /nodata,background=cgColor('white'),color=0,charthick=3,charsize=2.3,xminor=5,yrange=ylim-offset
        for j=0,3 do begin
             real = 0 ;check if it is a real correlation

;UNCOMMENT FOR CCD TEMP FIT FIRST
             if i le 3 then yval = avepix[j,ccdtyp]+olevel[0,j,ccdtyp]+olevel[1,j,ccdtyp] $; Add the temperature pedestal back in to find new correlation using CCD operating temperature first
                 else yval = newavepix[j,ccdtyp] 

;UNCOMMENT FOR CEB FIT FIRST
 ;            if labels[i] eq 'BT06CBPX' then yval = avepix[j,ccdtyp]+olevel[0,j,ccdtyp]+olevel[1,j,ccdtyp] $; Add the temperature pedestal back in to find new correlation using CCD operating temperature first
 ;                else yval = newavepix[j,ccdtyp] 
                     
             
             xval = otemps[i,ccdtyp];+otemps[i+(k+1)*4,ccdtyp]

; only use good data to fit
             good = where((xval gt xlim[0]) and (xval lt xlim[1]) and (yval gt ylim[0]) and (yval lt ylim[1]) and (time[ccdtyp] gt stime) and (time[ccdtyp] lt etime))
             good5 = where((xval gt xlim[0]) and (xval lt xlim[1]) and (yval gt ylim[0]) and (yval lt ylim[1]) and (time[ccdtyp] gt stime5) and (time[ccdtyp] lt etime5))
             good6 = where((xval gt xlim[0]) and (xval lt xlim[1]) and (yval gt ylim[0]) and (yval lt ylim[1]) and (time[ccdtyp] gt stime6) and (time[ccdtyp] lt etime6))
             fitr = poly_fit(xval[good],yval[good],1,sigma=sigma)

;Commented out for testing
;Store appro fits in arrays
             case 1 of
;UNCOMMENT FOR CCD TEMP FIT FIRST
                 ((type[k] eq 'FUV') and (j lt 2) and (labels[i] eq 'ITF1CCD1')): begin
;UNCOMMENT FOR CEB FIT FIRST
 ;                ((type[k] eq 'FUV') and (j lt 2) and (labels[i] eq 'BT06CBPX')): begin
                     fitpoly[j,*] = fitr ;FUV CCD1
                     real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                     ;Old temperature model
                     if j eq 0 then c0 =[6.57168,0.15872] else c0 = [6.62957,0.15932]
                   
                 end
;UNCOMMENT FOR CCD TEMP FIT FIRST
                 ((type[k] eq 'FUV') and (j gt 1) and (labels[i] eq 'ITF2CCD2')): begin
;UNCOMMENT FOR CEB FIT FIRST
 ;                ((type[k] eq 'FUV') and (j gt 1) and (labels[i] eq 'BT06CBPX')): begin
                     fitpoly[j,*] = fitr ;FUV CCD2
                     real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                     ;Old temperature model
                     if j eq 2 then c0 =[6.48711,0.15713] else c0 = [6.69489,0.16202]
                 end
;UNCOMMENT FOR CCD TEMP FIT FIRST
                 ((type[k] eq 'NUV') and (j gt 1) and (labels[i] eq 'ITNUCCD3')): begin
;UNCOMMENT FOR CEB FIT FIRST
 ;                ((type[k] eq 'NUV') and (j gt 1) and (labels[i] eq 'BT06CBPX')): begin
                      fitpoly[j+4,*] = fitr ;NUV
                      real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                     ;Old temperature model
                     if j eq 2 then c0 =[6.4848,0.15895] else c0 = [6.4783,0.15938]
                 end
;UNCOMMENT FOR CCD TEMP FIT FIRST
                 ((type[k] eq 'NUV') and (j lt 2) and (labels[i] eq 'ITSJCCD4')): begin
;UNCOMMENT FOR CEB FIT FIRST
 ;                ((type[k] eq 'NUV') and (j lt 2) and (labels[i] eq 'BT06CBPX')): begin
                      fitpoly[j+4,*] = fitr ;SJI
                      real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                     ;Old temperature model
                     if j eq 0 then c0 =[6.4821,0.15605] else c0 = [6.5912,0.15824]
                 end
                 ((labels[i] eq 'BT10HOPA')) : real=1
                 else: print,'Do Nothing'
             endcase


             
             if real eq 1 then begin 
                 oplot,xval,yval,color=color[j],psym=syms[j],thick=2
                 oplot,xval,newavepix[j,ccdtyp],color=color[j],psym=syms[j],thick=2
                 oplot,xval[good],yval[good],color=20,psym=syms[j],thick=2
                 oplot,xval[good5],yval[good5],color=120,psym=syms[j],thick=2
                 oplot,xval[good6],yval[good6],color=200,psym=syms[j],thick=2
                 oplot,xlim,poly(xlim,fitr),color=color[j],psym=0,thick=3,linestyle=j
                 sortx = sort(xval)
;                 oplot,xval[sortx],solevel[sortx],color=color[j],psym=0,thick=2 
                 crate = 1.03
                 bin = 1
;                 if real eq 1 then oplot,xval,crate*bin*exp(poly(xval-273.,c0)),color=color[j],psym=0,thick=2 
                 writeplot = 1
             endif
;             if i eq 0 then print,type[k]+' '+ports[j]+'Mean = '+strcompress(median(yval))+'+/-'+strcompress(stddev(yval)/sqrt(n_elements(yval)))
        endfor
        if writeplot eq 1 then begin
            al_legend,ports,psym=syms,colors=color,box=0,/right,charsize=2.0
            write_png,'plots/new_trend/'+type[k]+'_'+labels[i]+'.png',tvrd(/true)
        endif
    endfor

;check other CCD temperatures and their correlation with the excess
   

;store new CCD values in array
    nyval = fltarr(4,n_elements(ccdtyp))
    for i=0,3 do nyval[i,*] = newavepix[i,ccdtyp]
    jime = time[ccdtyp] 
;call function which returns an array of elements which splits the observations into groups
;    group_iris_darks,jime,newd
    get_binned_iris_dark_trend,nyval,jime,gropave,gropsig,groptim

    if type[k] eq 'FUV' then ylim = [-1,6] else ylim = [-1.0,1.5]
    ylim = [-1.0,1.5]




    dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
    utplot,[0,0],[0,0],'1-jan-12',/nodata,psym=0,linestyle=2,title=type[k],ytitle='Average Dark Offset (Dark-New Model) [ADU]',$
            xtitle=' Year [20XX]',xrange=[min(jime),max(jime)+3.*24.*3600.],$ ;yrange=[min(avepix[*,ccdtyp]),max(avepix[*,ccdtyp])],$
            background=cgColor('white'),color=0,charthick=3,charsize=2.3,xminor=5,yrange=ylim,XSTYLE=1
    for j=0,3 do begin
;        oplot,jime[ccdtyp],newavepix[j,ccdtyp],psym=syms[j],color=color[j]
        oplot,groptim,gropave[j,*],psym=syms[j],color=color[j]
        errplot,groptim,gropave[j,*]-gropsig[j,*],gropave[j,*]+gropsig[j,*],color=color[j],thick=2
    endfor

    ;Include vertical lines that represent when the bakeouts occured. These need to be manually updated for each bakeout. 
    bakeout_time=[julday(10,16,2014),julday(10,26,2015),julday(4,26,2016)]-normal

    for j=0,n_elements(bakeout_time)-1 do oplot,[bakeout_time[j],bakeout_time[j]]*24.*3600.,$
                                               [-1000.,1000.],linestyle=2,color='black',thick=2
    
    




    al_legend,ports,psym=syms,colors=color,box=0,/right,charsize=2.0
    write_png,'plots/new_trend/'+type[k]+'_new_long_term_trend.png',tvrd(/true)

endfor



end

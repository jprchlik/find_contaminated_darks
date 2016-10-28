pro plot_new_trend

loadct,12
restore,'../calc_trend_darks/alldark_ave_sig.sav'
;fname = 'alldark_ave_sig_no_dark_model.sav'
;restore,fname

type = ['NUV','FUV']
ports = ['port1','port2','port3','port4']
labels = ['FUV1','FUV2','NUV','SJI','CEB_POSX1', 'CEB_POSX2', 'CEB_POSX3', 'CEB_POSX4', 'CEB_NEGX1', 'CEB_NEGX2', 'CEB_NEGX3', 'CEB_NEGX4']
;labels = ['ped1','ped2']
;labels = ['Temp Poly','Dark Current','Pedestal Off']
syms = [4,5,6,7]
color= [0,100,120,200]

;create TIME array
jime = dblarr(n_elements(timeou))
normal = JULDAY(1,1,2012,0,0,0)
for i=0,n_elements(timeou)-1 do begin

     year  = fix(strmid(timeou[i],0,4))
     month = fix(strmid(timeou[i],5,2))
     day   = fix(strmid(timeou[i],8,2))
     hour  = fix(strmid(timeou[i],11,2))
     min   = fix(strmid(timeou[i],14,2))
     sec   = fix(strmid(timeou[i],17,2))
     jime[i] = JULDAY(month,day,year,hour,min,sec)-normal
endfor

jime = jime*24.*3600.


;get shape of avepix array
aveshape = size(avepix)

;create newly corrected CCD out values
newavepix = fltarr(aveshape[1],aveshape[2])

;change temperature to K 
otemps = otemps+273.


;level = alog10(olevel)

fitpoly = fltarr(8,2)

for k=0,n_elements(type)-1 do begin

    ccdtyp = where(strmatch(basicf,type[k]+'*',/FOLD_CASE) EQ 1)
    ntemps = size(otemps)
    ntemps = ntemps[1]

    nlevls = size(olevel)
    nlevls = nlevls[1]

    stime = (JULDAY(1,1,2014,0,0,0) -normal)*24.*3600.
    etime = (JULDAY(1,1,2016,0,0,0) -normal)*24.*3600.
  

    for i=0,3 do begin 
        xlim = [-65.,-52.]+273.
        
        writeplot=0
        if k eq 0 then ylim = [98.,104.] else ylim = [93.,105.]

;

;store poly fits
        plot,[0,0],[0,0],psym=0,linestyle=2,title=type[k],ytitle='Average Dark Offset (Dark-Model) [ADU]',$
            xtitle=labels[i]+' Temperature [K]',xrange=xlim, $ ;yrange=[min(avepix[*,ccdtyp]),max(avepix[*,ccdtyp])],$
            /nodata,background=cgColor('white'),color=0,charthick=3,charsize=2.3,xminor=5,yrange=ylim
        for j=0,3 do begin
             real = 0 ;check if it is a real correlation
             yval = avepix[j,ccdtyp]+olevel[0,j,ccdtyp]+olevel[1,j,ccdtyp] ; Add the temperature pedestal back in to find new correlation
             xval = otemps[i,ccdtyp];+otemps[i+(k+1)*4,ccdtyp]

; only use good data to fit
             good = where((xval gt xlim[0]) and (xval lt xlim[1]) and (yval gt ylim[0]) and (yval lt ylim[1]) and (jime[ccdtyp] gt stime) and (jime[ccdtyp] lt etime))
             fitr = poly_fit(xval[good],yval[good],1,sigma=sigma)

             case 1 of
                 ((k eq 1) and (j lt 2) and (i eq 0)): begin
                     fitpoly[j,*] = fitr ;FUV CCD1
                     real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                 end
                 ((k eq 1) and (j gt 1) and (i eq 1)): begin
                     fitpoly[j,*] = fitr ;FUV CCD2
                     real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                 end
                 ((k eq 0) and (j lt 2) and (i eq 2)): begin
                      fitpoly[j+4,*] = fitr ;NUV
                      real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                 end
                 ((k eq 0) and (j gt 1) and (i eq 3)): begin
                      fitpoly[j+4,*] = fitr ;SJI
                      real=1
                     ;store new ave pixel value
                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
                 end
                 else: print,'Do Nothing'
             endcase


             
             if real eq 1 then begin 
                 oplot,xval,yval,color=color[j],psym=syms[j],thick=2
                 oplot,xlim,poly(xlim,fitr),color=color[j],psym=0,thick=3,linestyle=j
                 writeplot = 1
             endif
;             if i eq 0 then print,type[k]+' '+ports[j]+'Mean = '+strcompress(median(yval))+'+/-'+strcompress(stddev(yval)/sqrt(n_elements(yval)))
        endfor
        if writeplot eq 1 then begin
            al_legend,ports,psym=syms,colors=color,box=0,/right,charsize=2.0
            write_png,'plots/new_trend/'+type[k]+'_'+labels[i]+'.png',tvrd(/true)
        endif
    endfor


;Now do fits for POSX and NEGX temperatures
    for i=4,11 do begin 
        xlim = [-1.,5.]+273.
        
        writeplot=0
        if k eq 0 then ylim = [-2,6] else ylim = [-2,6]

;

;store poly fits
        plot,[0,0],[0,0],psym=0,linestyle=2,title=type[k],ytitle='Average Dark Offset (Dark-Model) [ADU]',$
            xtitle=labels[i]+' Temperature [K]',xrange=xlim, $ ;yrange=[min(avepix[*,ccdtyp]),max(avepix[*,ccdtyp])],$
            /nodata,background=cgColor('white'),color=0,charthick=3,charsize=2.3,xminor=5,yrange=ylim
        for j=0,3 do begin
             real = 1 ;check if it is a real correlation
             yval = newavepix[j,ccdtyp] ; Add the temperature pedestal back in to find new correlation
             xval = otemps[i,ccdtyp];+otemps[i+(k+1)*4,ccdtyp]

; only use good data to fit
             good = where((xval gt xlim[0]) and (xval lt xlim[1]) and (yval gt ylim[0]) and (yval lt ylim[1]) and (jime[ccdtyp] gt stime) and (jime[ccdtyp] lt etime))
             fitr = poly_fit(xval[good],yval[good],1,sigma=sigma)

;             case 1 of
;                 ((k eq 1) and (j lt 2) and (i eq 0)): begin
;                     fitpoly[j,*] = fitr ;FUV CCD1
;                     real=1
;                     ;store new ave pixel value
;                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
;                 end
;                 ((k eq 1) and (j gt 1) and (i eq 1)): begin
;                     fitpoly[j,*] = fitr ;FUV CCD2
;                     real=1
;                     ;store new ave pixel value
;                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
;                 end
;                 ((k eq 0) and (j lt 2) and (i eq 2)): begin
;                      fitpoly[j+4,*] = fitr ;NUV
;                      real=1
;                     ;store new ave pixel value
;                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
;                 end
;                 ((k eq 0) and (j gt 1) and (i eq 3)): begin
;                      fitpoly[j+4,*] = fitr ;SJI
;                      real=1
;                     ;store new ave pixel value
;                     newavepix[j,ccdtyp]  = yval-poly(xval,fitr)
;                 end
;                 else: print,'Do Nothing'
;             endcase


             
             if real eq 1 then begin 
                 oplot,xval,yval,color=color[j],psym=syms[j],thick=2
                 oplot,xlim,poly(xlim,fitr),color=color[j],psym=0,thick=3,linestyle=j
                 writeplot = 1
             endif
;             if i eq 0 then print,type[k]+' '+ports[j]+'Mean = '+strcompress(median(yval))+'+/-'+strcompress(stddev(yval)/sqrt(n_elements(yval)))
        endfor
        if writeplot eq 1 then begin
            al_legend,ports,psym=syms,colors=color,box=0,/right,charsize=2.0
            write_png,'plots/new_trend/'+type[k]+'_'+labels[i]+'.png',tvrd(/true)
        endif
    endfor

; New time plots
    dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
    utplot,[0,0],[0,0],'1-jan-12',/nodata,psym=0,linestyle=2,title=type[k],ytitle='Average Dark Offset (Dark-New Model) [ADU]',$
            xtitle=' Year [20XX]',xrange=[min(jime),max(jime)],$ ;yrange=[min(avepix[*,ccdtyp]),max(avepix[*,ccdtyp])],$
            background=cgColor('white'),color=0,charthick=3,charsize=2.3,xminor=5,yrange=[-5,5],XSTYLE=1
    for j=0,3 do begin
        oplot,jime[ccdtyp],newavepix[j,ccdtyp],psym=syms[j],color=color[j]
        print,median(newavepix[j,ccdtyp])
    endfor
    al_legend,ports,psym=syms,colors=color,box=0,/right,charsize=2.0
    write_png,'plots/new_trend/'+type[k]+'_new_long_term_trend.png',tvrd(/true)

endfor



end

pro format_for_steve_eps
    set_plot,'PS'
    loadct,12
    !P.THICK = 5
    
;need to produce ti,avi, and avni
    resolve_routine,'get_binned_iris_dark_trend',/COMPILE_FULL_FILE


    restore,'alldark_ave_sig.sav'

    type = ['NUV','FUV']
    ports = ['port1','port2','port3','port4']

;use anytim start date which is 1-jan-1979
    normal = JULDAY(1,1,1979,0,0,0)

    string_to_time,timeou,time,normal=normal ;convert file name to string default is Jan 1, 2012
    
    time = time*24.*3600. ;covert JULDAY to seconds


    for i=0,n_elements(type)-1 do begin

        ccdtyp = where(strmatch(basicf,type[i]+'*',/FOLD_CASE) eq 1)

 


        get_binned_iris_dark_trend,avepix[*,ccdtyp],time[ccdtyp],gropave,gropsig,groptim

        ;Newest day to plot
        maxdayplot  = anytim('2017-jul-01')
        if type[i] eq 'NUV' then begin 
            cut = 0.12
            goodday = where((gropsig[0,*] lt cut) and (gropsig[1,*] lt cut) and (gropsig[2,*] lt cut) and (gropsig[3,*] lt cut) and (groptim lt maxdayplot));emperically derived  to remove November 2015
;create new arrays where all ports pass
            gropave = gropave[*,goodday]
            gropsig = gropsig[*,goodday]
            groptim = groptim[goodday]
            sigmx = gropsig[*,2:*] ;remove 2013 points
            fname = 'offset30n.dat'
            avni = gropave[*,2:*]
            tni = groptim[2:*]
            xoff = [1.0e7,1.0e7,1.0e7,1.0e7]
            yoff = [-0.30,-0.30,-0.25,-0.15]
            ;save,sigmx,avni,tni,xoff,yoff,filename=fname
         endif else begin
            cut = 0.20
            goodday = where((gropsig[0,*] lt cut) and (gropsig[1,*] lt cut) and (gropsig[2,*] lt cut) and (gropsig[3,*] lt cut) and (groptim lt maxdayplot));emperically derived  to remove November 2015
;create new arrays where all ports pass
            gropave = gropave[*,goodday]
            gropsig = gropsig[*,goodday]
            groptim = groptim[goodday]
            sigmx = gropsig[*,2:*] ;remove 2013 points
            fname = 'offset30f.dat'
            avi = gropave[*,2:*]
            ti = groptim[2:*]
            xoff = [1.0e7,1.0e7,1.0e7,1.0e7]
            yoff = [-0.25,-0.50,-1.80,-0.60]
            ;save,sigmx,avi,ti,xoff,yoff,filename=fname
         endelse

;ADDED TO) CHECK TO MAKE SURE DATA MAKES SENSE
;get number of days which span observations
        spanday = time[n_elements(time)-1]-time[0]+normal-180.
        spanday = spanday/24./3600.
;       spanday = 900

        ;Covert groptim from anytime to JULIAN Day format
        gropjim = groptim/24./3600.+normal

; Create date span line for plot fit
;Then put in format that iris_dark_trend_fix uses
       spanarray = TIMEGEN(spanday+180,START=time[0]/24./3600.-180.)+normal
       ppanarray = spanarray
       tpanarray = fltarr(n_elements(spanarray))
       offsets = fltarr(4,n_elements(spanarray))
        for j=0,n_elements(spanarray)-1 do begin
            CALDAT,spanarray[j],mon,day,year
            fmtst = '(I4,"/",I02,"/",I02,"T",I02,":",I02,":",I02)'
            indat = string(year,mon,day,0,0,0,format=fmtst)
            tpanarray[j] = anytim(indat)
            iris_dark_trend_fix,indat,doffsets,type[i]
            offsets[*,j] = doffsets
        endfor

;put span array back into jime day reference
        upanarray = double(anytim(tpanarray))
        spanarray = spanarray-normal
        spanarray = spanarray*24.*3600.
        
        ;File name for plotting
        fname = pdir+'/'+type[i]+'_test2.eps'
        device,filename=fname,encap=1,/helvetica,xsize=9.0,ysize=6.0,/inch

        ;Xtick location and labels
        xtick_val = double(julday(01,01,[2014,2015,2016,2017,2018]))
        xtick_str = ['2014-01','2015-01','2016-01','2017-01','2018-01']

        ;Different limits for different types
        if type[i] eq 'NUV' then ylim = [-5,10] else ylim = [-5,15]
        


        ;Pad in days
        daypad = 180

        dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
   ;set up the plot 
        plot,spanarray,gropave[0,*],ytitle="Average Offset Dark-Model [DN]",title=type[i]+' Dark Pedestal Evolution',$
            XSTYLE=1, xtitle='Date',xticks=4,Color=cgColor('black'),$
            xtickv=xtick_val,xtickname=xtick_str, $
            xrange=[min(xtick_val)-daypad,max(xtick_val)+daypad/3],$
            /nodata,yrange=ylim,background=cgColor('white'),$
            charthick=3,charsize=1.7,xminor=12;yrange=[80,120]


    ;set up symbolts and colors for ports
        syms = [4,5,6,7]
        color = [0,100,120,200]
        lines = [0,4,2,3]

  
; loop and plot each port individually
        for j=0,3 do begin
    ;        port = yval[i,*]
    ;        oplot,jime,port,psym=syms[i],color=color[i]
            port = gropave[j,*]
            porte = gropsig[j,*]
            oplot,gropjim,port,psym=syms[j],color=color[j],thick=3
            errplot,gropjim,port-porte,port+porte,color=color[j],thick=3
   ;overplot long term trend
   ;        oplot,groptim,groptrd[i,*],color=color[i],psym=0,linestyle=lines[i]
            oplot,ppanarray,offsets[j,*],color=color[j],psym=0,linestyle=lines[j],thick=9

        endfor

        al_legend,['port1','port2','port3','port4'],psym=syms,colors=color,linestyle=lines,box=0,/top,charsize=2.0
        ;al_legend,['fit port1','fit port2','fit port3','fit port4'],psym=[0,0,0,0],colors=colors,linestyle=lines,box=0,/right,charsize=2.0

        device,/close
        ;write_png,pdir+'/'+type[i]+'_test2.png',tvrd(/true)


    endfor


end

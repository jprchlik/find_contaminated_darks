pro format_for_steve

    loadct,12
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

        if type[i] eq 'NUV' then begin 
            sigmx = gropsig[*,1:*]
            fname = 'offset30n.dat'
            avni = gropave[*,1:*]
            tin = groptim[1:*]
            xoff = [1.0e7,1.0e7,1.0e7,1.0e7]
            yoff = [-0.30,-0.30,-0.25,-0.15]
            save,sigmx,avni,tin,xoff,yoff,filename=fname
         endif else begin
            sigmx = gropsig[*,1:*]
            fname = 'offset30f.dat'
            avi = gropave[*,1:*]
            ti = groptim[1:*]
            xoff = [1.0e7,1.0e7,1.0e7,1.0e7]
            yoff = [-0.25,-0.50,-1.80,-0.60]
            save,sigmx,avi,ti,xoff,yoff,filename=fname
         endelse

;ADDED TO) CHECK TO MAKE SURE DATA MAKES SENSE
;get number of days which span observations
        spanday = time[n_elements(time)-1]-time[0]+normal
        spanday = spanday/24./3600.
        print,spanday
;       spanday = 900

; Create date span line for plot fit
;Then put in format that iris_dark_trend_fix uses
       spanarray = TIMEGEN(spanday,START=time[0]/24./3600.)+normal
       offsets = fltarr(4,n_elements(spanarray))
        for j=0,n_elements(spanarray)-1 do begin
            CALDAT,spanarray[j],mon,day,year
            indat = strcompress(year,/remove_all)+'/'+strcompress(mon,/remove_all)+'/'+strcompress(day,/remove_all)
           
            iris_dark_trend_fix,indat,doffsets,type[i]
            offsets[*,j] = doffsets
        endfor

;put span array back into jime day reference
        spanarray = spanarray-normal
        spanarray = spanarray*24.*3600.



       print,'HERE 2'


        dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
   ;set up the plot 
        utplot,[0,0],[0,0],'1-jan-79',ytitle="Average Offset Dark-Model [ADU]",title=type[i]+' Dark Pixel Evolution',$
            XSTYLE=1,$;timerange=['24-aug-16,05:59:00','24-aug-16,8:00:00'],$
            xrange=[min(time)-3*240.*3600.,max(time)+3*240.*3600.],$
            /nodata,yrange=[-5,9],background=cgColor('white'),color=0,$
            charthick=3,charsize=2.5,xminor=12,xtitle='Year [20XX]' ;yrange=[80,120]


    ;set up symbolts and colors for ports
        syms = [4,5,6,7]
        color = [0,100,120,200]
        lines = [0,1,2,3]

  
; loop and plot each port individually
        for j=0,3 do begin
    ;        port = yval[i,*]
    ;        oplot,jime,port,psym=syms[i],color=color[i]
            port = gropave[j,*]
            porte = gropsig[j,*]
            oplot,groptim,port,psym=syms[j],color=color[j],thick=2
            errplot,groptim,port-porte,port+porte,color=color[j],thick=2
   ;overplot long term trend
   ;        oplot,groptim,groptrd[i,*],color=color[i],psym=0,linestyle=lines[i]
            oplot,spanarray,offsets[j,*],color=color[j],psym=0,linestyle=lines[j],thick=3

        endfor

        al_legend,['port1','port2','port3','port4'],psym=syms,colors=color,linestyle=[0,0,0,0],box=0,/top,charsize=2.0
        al_legend,['fit port1','fit port2','fit port3','fit port4'],psym=[0,0,0,0],colors=colors,linestyle=lines,box=0,/right,charsize=2.0

        write_png,pdir+'/'+type[i]+'_test.png',tvrd(/true)


    endfor


end

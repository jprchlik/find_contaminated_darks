pro plot_dark_trend,time,yval


type = ['NUV','FUV']
for z=0,1 do begin
    ;julian time array
        jime = dblarr(n_elements(time))
    ;set counting time
        normal = JulDay(1,1,2012,0,0,0)
    
        ;Convert time into julian days
        for i=0,n_elements(jime)-1 do begin
            itype = strmid(time[i],0,3)
;Work only on values for FUV or NUV
            if itype eq type[z] then begin
                iyear  = uint(strmid(time[i],3,4))
                imonth = uint(strmid(time[i],7,2))
                iday   = uint(strmid(time[i],9,2))
                ihour  = uint(strmid(time[i],12,2))
                imin   = uint(strmid(time[i],14,2))
                isec   = uint(strmid(time[i],16,2))
        ;      print,imonth,iday,iyear,ihour,imin,isec
                jime[i] = JULDAY(imonth,iday,iyear,ihour,imin,isec)-normal
        ;       print,jime[i]
            endif
        endfor
    
       ;remove observations from other CCD (i.e. examine only NUV or FUV)
       keep = where(jime gt 0)
       jime = jime[keep]
      ;testing
       ttime = time[keep]
       nyval= fltarr(4,n_elements(jime))
       for j=0,3 do begin
           nyval[j,*] = yval[j,keep]
       endfor
       
    
    ;find observations less than one day apart and group them
       sime = jime[bindgen(n_elements(jime)-2)+1]
       eime = jime[bindgen(n_elements(jime)-2)]
    
       adif = sime-eime
    
       newd = where(adif gt .5)
       gropave = fltarr(4,n_elements(newd))
       gropsig = fltarr(4,n_elements(newd))
       groptim = dblarr(n_elements(newd))
    
       print,newd
       print,n_elements(newd)
       print,n_elements(jime),n_elements(ttime)
       for i=0,n_elements(newd)-1 do begin
           print,'NEW'
    
           case i of 
               0: grouparray = bindgen(newd[i])
               else: grouparray = bindgen(newd[i]-newd[i-1])+newd[i-1]+1
           endcase
           case i of
               0:print,newd[i]
               else:print,newd[i]-newd[i-1],newd[i-1]+1,newd[i]
           endcase
           print,n_elements(grouparray),grouparray[0],grouparray[n_elements(grouparray)-1]
           for j=0,3 do begin       
               gropave[j,i] = mean(nyval[j,grouparray])
               gropsig[j,i] = stddev(nyval[j,grouparray])
           endfor
           groptim[i] = jime[newd[i]]
       
        endfor 
       
        ;convert time to seconds since normalized day
        jime = (jime)*24.*3600.
        groptim = groptim*24.*3600.
      
        dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
    
        utplot,[0,0],[0,0],'1-jan-12',ytitle="Average Pixel Value",title=type[z]+' Dark Pixel Evolution',$
            XSTYLE=1,$;timerange=['24-aug-16,05:59:00','24-aug-16,8:00:00'],$
            xrange=[min(jime)-3*240.*3600.,max(jime)+3*240.*3600.],$
            /nodata,yrange=[-1,5],background=cgColor('white'),color=0,$
            charthick=3,charsize=2.5 ;yrange=[80,120]
    
    
        syms = [4,5,6,7]
        color = [0,0,0,0]
    
        for i=0,3 do begin
    ;        port = yval[i,*]
    ;        oplot,jime,port,psym=syms[i],color=color[i]
            port = gropave[i,*]
            oplot,groptim,port,psym=syms[i],color=color[i]
        endfor
    
        al_legend,['port1','port2','port3','port4'],psym=syms,colors=color,linestyle=color,box=0,/top,charsize=2.0
    
        write_png,'plots/'+type[z]+'_test.png',tvrd(/true)
    
    
    ;    p.Save, "test.png",BORDER=10,$
    ;        RESOLUTION=300,/TRANSPARENT
endfor
end

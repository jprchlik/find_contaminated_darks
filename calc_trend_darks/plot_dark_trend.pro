pro plot_dark_trend,time,yval,sdir=sdir,pdir=pdir

loadct,12
if keyword_set(sdir) then sdir=sdir else sdir='/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/'
if keyword_set(pdir) then pdir=pdir else pdir='plots/'

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
       sime = jime[indgen(n_elements(jime)-2)+1]
       eime = jime[indgen(n_elements(jime)-2)]
    
       adif = sime-eime
    
;Set looking area to be 10 days different from previous value (might be too inclusive but darks are ~30 days apart)
       newd = where(adif gt 10.5)

;Add one to newd to offset one less elements
       newd = newd+1
;Add first and last pixe values
       newd = [0,newd,n_elements(jime)]

       gropave = fltarr(4,n_elements(newd))
       gropsig = fltarr(4,n_elements(newd))
       groptrd = fltarr(4,n_elements(newd)) ;Steve's predicted long term trend
       groptim = dblarr(n_elements(newd))
    
       print,'Split Day'

;Since value in greater than 255 must use dindgen instead of indgen
       indices = dindgen(n_elements(jime))

;       for i=0,n_elements(newd) do print,ttime[newd[i]],' ',ttime[newd[i]+1]
       for i=1,n_elements(newd)-1 do begin
           grouparray = where((indices ge newd[i-1]) and (indices lt newd[i]))


;find the first file in day
           ffile = ttime[grouparray[0]]
           syear = strmid(ffile,3,4)
           smonth= strmid(ffile,7,2)
           readfi = sdir+'/'+syear+'/'+smonth+'/'+ffile
;Find Steve's long term trend
           read_iris,readfi,index,data
           iris_dark_trend_fix,index,ltoff

;Save offsets in arrays 
           groptrd[*,i] = ltoff
           for j=0,3 do begin       
               gropave[j,i] = mean(nyval[j,grouparray])
;use the error in the mean for the error
               gropsig[j,i] = stddev(nyval[j,grouparray])/float(n_elements(grouparray))
           endfor
           groptim[i] = mean(jime[grouparray])
       
        endfor 
       
        ;convert time to seconds since normalized day
        jime = (jime)*24.*3600.
        groptim = groptim*24.*3600.
      
        dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
   ;set up the plot 
        utplot,[0,0],[0,0],'1-jan-12',ytitle="Average Offset Dark-Model [ADU]",title=type[z]+' Dark Pixel Evolution',$
            XSTYLE=1,$;timerange=['24-aug-16,05:59:00','24-aug-16,8:00:00'],$
            xrange=[min(jime)-3*240.*3600.,max(jime)+3*240.*3600.],$
            /nodata,yrange=[-5,9],background=cgColor('white'),color=0,$
            charthick=3,charsize=2.5,xminor=12 ;yrange=[80,120]
    
    
    ;set up symbolts and colors for ports
        syms = [4,5,6,7]
        color = [0,100,120,200]
        lines = [0,1,2,3]
    
;loop and plot each port individually
        for i=0,3 do begin
    ;        port = yval[i,*]
    ;        oplot,jime,port,psym=syms[i],color=color[i]
            port = gropave[i,*]
            porte = gropsig[i,*]
            oplot,groptim,port,psym=syms[i],color=color[i]
            errplot,groptim,port-porte,port+porte,color=color[i]
   ;overplot long term trend
            oplot,groptim,groptrd[i,*],color=color[i],psym=0,linestyle=lines[i]
        endfor
    
        al_legend,['port1','port2','port3','port4'],psym=syms,colors=color,linestyle=[0,0,0,0],box=0,/top,charsize=2.0
        al_legend,['port1','port2','port3','port4'],psym=[0,0,0,0],colors=colors,linestyle=lines,box=0,/right,charsize=2.0
    
        write_png,pdir+'/'+type[z]+'_test.png',tvrd(/true)
    
    
    ;    p.Save, "test.png",BORDER=10,$
    ;        RESOLUTION=300,/TRANSPARENT
endfor
end

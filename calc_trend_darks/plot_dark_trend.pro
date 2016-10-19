pro plot_dark_trend,time,yval

;julian time array
    jime = dblarr(n_elements(time))
;set counting time
    normal = JulDay(1,1,2012,0,0,0)

    ;Convert time into julian days
    for i=0,n_elements(jime)-1 do begin
        iyear  = uint(strmid(time[i],3,4))
        imonth = uint(strmid(time[i],7,2))
        iday   = uint(strmid(time[i],9,2))
        ihour  = uint(strmid(time[i],12,2))
        imin   = uint(strmid(time[i],14,2))
        isec   = uint(strmid(time[i],16,2))
        
;      print,imonth,iday,iyear,ihour,imin,isec
        jime[i] = JULDAY(imonth,iday,iyear,ihour,imin,isec)-normal
;       print,jime[i]
    endfor
 
   
    ;convert time to seconds since normalized day
    jime = (jime)*24.*3600.
  
    dummy = LABEL_DATE(DATE_FORMAT=["%M","%Y"])

    utplot,[0,0],[0,0],'1-jan-12',ytitle="Average Pixel Value",title='Dark Pixel Evolution',$
        XSTYLE=1,$;timerange=['24-aug-16,05:59:00','24-aug-16,8:00:00'],$
        xrange=[min(jime)-3*240.*3600.,max(jime)+3*240.*3600.],$
        /nodata,yrange=[80,120]


    syms = [4,5,6,7]
    color = [0,0,0,0]

    for i=0,3 do begin
        port = yval[i,*]
        oplot,jime,port,psym=syms[i]
    endfor

    al_legend,['port1','port2','port3','port4'],psym=syms,colors=color,box=0,/left


;    p.Save, "test.png",BORDER=10,$
;        RESOLUTION=300,/TRANSPARENT
end

pro plot_temp_trend,sdir=sdir,pdir=pdir

restore,'alldark_ave_sig.sav'
; Make a vector of 16 points, A[i] = 2pi/16:
A = FINDGEN(17) * (!PI*2/16.)
; Define the symbol to be a unit circle with 16 points, 
; and set the filled flag:
USERSYM, COS(A), SIN(A), /FILL
;set up symbolts and colors for ports
syms = [1,2,5,4,1,2,4,2,5,6,7,8,0]
color = [0,100,120,200,0,100,120,200,0,100,120,200]
labels = ['FUV1','FUV2','NUV','SJI','CEB_POSX1', 'CEB_POSX2', 'CEB_POSX3', 'CEB_POSX4', 'CEB_NEGX1', 'CEB_NEGX2', 'CEB_NEGX3', 'CEB_NEGX4']
lines = [0,1,2,3]
ports = ['port1','port2','port3','port4']


yval = avepix
time = basicf

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
;Find number of temperatures used in model
       ntemps = size(otemps)
       ntemps = ntemps[1]
;Find number of ports used in model
       nports = size(yval)
       nports = nports[1]
    
       ;remove observations from other CCD (i.e. examine only NUV or FUV)
       keep = where(jime gt 0)
       jime = jime[keep]
      ;testing
       ttime = time[keep]
       nyval= fltarr(ntemps,n_elements(jime))
       for j=0,ntemps-1 do begin
           nyval[j,*] = otemps[j,keep]
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



;initalize array for finding averages
       gropave = fltarr(ntemps,n_elements(newd))
       gropsig = fltarr(ntemps,n_elements(newd))
       groptrd = fltarr(ntemps,n_elements(newd)) ;Steve's predicted long term trend
;group pixel values
       pixeave = fltarr(nports,n_elements(newd))
       pixesig = fltarr(nports,n_elements(newd))
       groptim = dblarr(n_elements(newd))
    
;Since value in greater than 255 must use dindgen instead of indgen
       indices = dindgen(n_elements(jime))


;       for i=0,n_elements(newd) do print,ttime[newd[i]],' ',ttime[newd[i]+1]
       for i=1,n_elements(newd)-1 do begin
           grouparray = where((indices ge newd[i-1]) and (indices lt newd[i]))


;Save offsets in arrays 
           for j=0,ntemps-1 do begin       
               gropave[j,i] = mean(nyval[j,grouparray])
;use the error in the mean for the error
               gropsig[j,i] = stddev(nyval[j,grouparray])/sqrt(float(n_elements(grouparray)))
               if gropsig[j,i] gt 20 then gropsig[j,i] = 0 ;removes 1 bad point for now
;get pixel difference values
               if j lt nports then begin
                   pixeave[j,i] = mean(yval[j,grouparray])
                   pixesig[j,i] = stddev(yval[j,grouparray])/sqrt(n_elements(grouparray))
                   if pixesig[j,i] gt 20 then pixesig[j,i] =0
               endif
           endfor
           groptim[i] = mean(jime[grouparray])
       
        endfor 
;get number of days which span observations
        spanday = jime[n_elements(jime)-1]-jime[0]


; Create date span line for plot fit
;Then put in format that iris_dark_trend_fix uses
        spanarray = TIMEGEN(spanday,START=jime[0])+JULDAY(1,1,2012,0,0,0)
        offsets = fltarr(4,n_elements(spanarray))
        for i=0,n_elements(spanarray)-1 do begin
            CALDAT,spanarray[i],mon,day,year
            indat = strcompress(year,/remove_all)+'/'+strcompress(mon,/remove_all)+'/'+strcompress(day,/remove_all) 
            iris_dark_trend_fix,indat,doffsets,type[z]
            offsets[*,i] = doffsets
        endfor

;plot temperatures and ave pixels binned by day

        for p=0,ntemps-1 do begin
             ;ylim = [min(gropave),max(gropave)]
             ;xlim = [min(pixeave),max(pixeave)]
             ylim = [-5,10]
             if min(gropave[p,*]) gt -40 then xlim = [-0,3] else xlim=[-66,-58]
        
             plot,[0,0],[0,0],ytitle='Dark Pixel Value [ADU]',title=type[z],$
                 XSTYLE=1,xrange=xlim,/nodata,yrange=ylim,background=cgColor('white'),$
                 color=0,charthick=3,charsize=2.5,xminor=5,xtitle=labels[p]+' Temperature [K]'
              for k=0,nports-1 do begin
                  oplot,gropave[p,*],pixeave[k,*],color=color[k],psym=syms[k],thick=2
                  errplot,gropave[p,*],pixeave[k,*]-pixesig[k,*],pixeave[k,*]+pixesig[k,*],color=color[k],thick=1.5
              endfor
              al_legend,ports,colors=color[0:3],psym=syms[0:3],box=0,/top,charsize=2.0
             
              write_png,pdir+'/bined/'+type[z]+'_temp_'+labels[p]+'_cor.png',tvrd(/true),xres=3000,yres=3000
         endfor
              


;put span array back into jime day reference
        spanarray = spanarray-JULDAY(1,1,2012,0,0,0)
        spanarray = spanarray*24.*3600.

       
        ;convert time to seconds since normalized day
        jime = (jime)*24.*3600.
        groptim = groptim*24.*3600.
    
      
        dummy = LABEL_DATE(DATE_FORMAT=["%D-%M-%Y"])
        ymins = [-10.,-70.]
        ymaxs = [10.,-55]
        for p=0,n_elements(ymins)-1 do begin
   ;set up the plot 
            utplot,[0,0],[0,0],'1-jan-12',ytitle="Measured Temperature [C]",title=type[z]+' Dark Pixel Evolution',$
                XSTYLE=1,$;timerange=['24-aug-16,05:59:00','24-aug-16,8:00:00'],$
                xrange=[min(jime)-3*240.*3600.,max(jime)+3*240.*3600.],$
                /nodata,yrange=[ymins[p],ymaxs[p]],background=cgColor('white'),color=0,$
                charthick=3,charsize=2.5,xminor=12,xtitle='Year [20XX]' ;yrange=[80,120]
        
        
        
            k=0
    ;loop and plot each port individually
            for i=0,ntemps-1 do begin ;ntemps-1 do begin
        ;        port = yval[i,*]
        ;        oplot,jime,port,psym=syms[i],color=color[i]
                port = gropave[i,*]
                porte = gropsig[i,*]
                oplot,groptim,port,thick=2,psym=syms[i],color=color[i];color=color[i],thick=2
                ;errplot,groptim,port-porte,port+porte,color=0,thick=2;color=color[i],thick=2
       ;overplot long term trend
       ;        oplot,groptim,groptrd[i,*],color=color[i],psym=0,linestyle=lines[i]
                
               if k lt 4 then oplot,spanarray,2.0-offsets[k,*],color=color[k],psym=0,linestyle=lines[k],thick=3
               if k lt 4 then oplot,spanarray,-62.-offsets[k,*],color=color[k],psym=0,linestyle=lines[k],thick=3
               k = k+1
            
            endfor
        
            if p eq 0 then al_legend,labels[4:11],psym=syms[4:11],colors=color[4:11],box=0,/bottom,charsize=2.0
            if p eq 1 then al_legend,labels[0:3],psym=syms[0:3],colors=color[0:3],box=0,/bottom,charsize=2.0
            al_legend,['fit port1','fit port2','fit port3','fit port4'],psym=[0,0,0,0],colors=colors,linestyle=lines,box=0,/right,charsize=2.0
        
            write_png,pdir+'/temps/'+type[z]+'_'+strcompress(p,/remove_all)+'_test.png',tvrd(/true),xresolution=3000,yresolution=3000


    
        endfor    

endfor
end

pro make_saa_plot,month,year,type,outdir,plotdir=plotdir
    set_plot,'Z'



    ;output plot file name
    fname = type+'_'+year+'_'+month+'.eps'

    ;add plot directory
    if keyword_set(plotdir) then fname=plotdir+'/'+fname

    ;setup plot device
    set_plot,'ps'
    device,/encap,/color,filename=fname
    loadct,12

   
    
    
    readcol,outdir+type+'_'+year+'_'+month+'.txt',file,time,pass,numb,intt,format='A,A,f,f,f',delimiter=' ',skipline=1
    ;set artificial counting time
    normal = JulDay(1,1,2012,0,0,0)

    jime = dblarr(n_elements(time))

    ;Convert time into julian days
    for i=0,n_elements(jime)-1 do begin
        iyear  = uint(strmid(file[i],3,4))
        imonth = uint(strmid(file[i],7,2))
        iday   = uint(strmid(file[i],9,2))
        ihour  = uint(strmid(file[i],12,2))
        imin   = uint(strmid(file[i],14,2))
        isec   = uint(strmid(file[i],16,2))
        
;      print,imonth,iday,iyear,ihour,imin,isec
        jime[i] = JULDAY(imonth,iday,iyear,ihour,imin,isec)-normal
;       print,jime[i]
    endfor
 
   
    ;convert time to seconds since normalized day
    jime = (jime)*24.*3600.
  
    dummy = LABEL_DATE(DATE_FORMAT=["%H:%I","%D"])

;group Darks which pass and fail inspection
    good = where(pass eq 1)
    bad  = where(pass eq 0)
;start day to output tile
    sday = strmid(file[0],9,2)
    
    utplot,[0,0],[0,0],'1-jan-12',ytitle="Normalized Number of 5 Sigma Pixels",title=year+'/'+month+'/'+sday,$
        xtitle='Hours (UT)',XSTYLE=1,$;timerange=['24-aug-16,05:59:00','24-aug-16,8:00:00'],$
        xrange=[min(jime),max(jime)],$
        /nodata,yrange=[0,max(numb)]


;overplot good and bad points
;fix for empty good array
        if n_elements(size(good)) gt 3 then oplot,jime[good],numb[good],psym=6,color=0
;fix for empty bad array
        if n_elements(size(bad)) gt 3 then oplot,jime[bad],numb[bad],psym=6,color=200


;manually set SAA for now
        saai = double(JulDAY(09,21,2016,18,09)-normal)*24.*3600.
        saao = double(JulDAY(09,21,2016,18,26)-normal)*24.*3600.
        yval = [-10000,10000]
;overplot SAA
        oplot,[saai,saai],yval,psym=10,linestyle=2,color=0
        oplot,[saao,saao],yval,psym=10,linestyle=2,color=0
   


    al_legend,['Pass','Fail','SAA'],psym=[6,6,0],linestyle=[0,0,2],colors=[0,200,0],box=0

    device,/close,/encap

    
    



end


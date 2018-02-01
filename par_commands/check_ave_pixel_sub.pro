pro check_ave_pixel_sub,file,endfile,timfile,avepix,sigpix,temps,levels,writefile=writefile
;file is file name data is an array containing whether the ports passed or failed (1 is pass 0 is failed)
    compile_opt idl2
;    read_iris,file,index,data
;read in iris data
    read_iris,file,hdr,data
    print,file

;get file time 
    splfile = strsplit(file,'/',/extract)
    endfile = splfile[n_elements(splfile) - 1]
    year  = strmid(endfile,3,4)
    month = strmid(endfile,7,2)
    day   = strmid(endfile,9,2)
    hour  = strmid(endfile,12,2)
    min   = strmid(endfile,14,2)
    sec   = strmid(endfile,16,2)
  
    ;get plus/minus one day in temperatures
    caldat,double(julday(fix(month),fix(day),fix(year)))-1,month_1,day_1,year_1
    caldat,double(julday(fix(month),fix(day),fix(year)))+1,month_2,day_2,year_2


    ;file format
    f_fmt = '(I4,I02,I02)'
    ;Turn the integers into strings
    file_1 = string([year_1,month_1,day_1],format=f_fmt)
    file_2 = string([year_2,month_2,day_2],format=f_fmt)

    timfile = year+'/'+month+'/'+day+'T'+hour+':'+min+':'+sec
;read in dark data from the day before
    readcol,'../temps/'+file_1+'_iris_temp.fmt',date_obs_1,tccd1_1,tccd2_1,tccd3_1,tccd4_1,bt06_1,bt07_1,format='A,f,f,f,f,f,f',/silent,skipline=1
;read in dark data from that day
    readcol,'../temps/'+year+month+day+'_iris_temp.fmt',date_obs,tccd1,tccd2,tccd3,tccd4,bt06,bt07,format='A,f,f,f,f,f,f',/silent,skipline=1
;read in dark data from the day 
    readcol,'../temps/'+file_2+'_iris_temp.fmt',date_obs_2,tccd1_2,tccd2_2,tccd3_2,tccd4_2,bt06_2,bt07_2,format='A,f,f,f,f,f,f',/silent,skipline=1

    ; Only use temperature files if year less than 2015 (i.e. 2014) otherwise you header index 2018/01/31 J. Prchlik
    ; Actually no you want to use the temperature files according to iris_make_dark 2018/01/31 J. Prchlik
    ;if year lt 2015 then begin
    ;   create julian day array
    ;Add all temp observations into 1 day 
    date_obs = [date_obs_1,date_obs,date_obs_2]
    time_tab = dblarr(n_elements(date_obs))


    for i=0,n_elements(date_obs)-1 do begin
        timet = date_obs[i]
        year  = fix(strmid(timet,0,4))
        month = fix(strmid(timet,5,2))
        day   = fix(strmid(timet,8,2))
        hour  = fix(strmid(timet,11,2))
        min   = fix(strmid(timet,14,2))
        sec   = fix(strmid(timet,17,2))
        time_tab[i] = julday(month,day,year,hour,min,sec)
    endfor


    temp_tab = [[tccd1_1,tccd1,tccd1_2],[tccd2_1,tccd2,tccd2_2],[tccd3_1,tccd3,tccd3_2],[tccd4_1,tccd4,tccd4_2],[bt06_1,bt06,bt06_2],[bt07_1,bt07,bt07_2]]
    temp_tab = transpose(temp_tab)
    iris_make_dark,hdr,dark,temps,date_obs,temp_tab,levels
    ; Use header to make dark 2018/01/31 J. Prchlik
    ;Back to always using temperature tables 2018/01/29 J. Prchlik
    ;endif else iris_make_dark,hdr,dark ;,temps,date_obs,temp_tab,levels
    
;give data to iris_prep_dark subtracts off temperature and base line dark model
;
;;remove calculated dark from data
    data = data-dark
   ;switch to iris prep dark per converation with steve (2016/12/13 J. Prchlik)
;    iris_prep,hdr,data,ohdr,odata
;    hdr = ohdr
;    data = odata
   

    odir = '/Volumes/Pegasus/jprchlik/iris/find_con_darks/calc_trend_darks/fits_files/'

    ofil = strsplit(file,'/',/extract)
    ofil = ofil[n_elements(ofil)-1]

    
;split data into ports
    port1 = data[0:2071,0:547]
    port2 = data[0:2071,548:*]
    port3 = data[2072:*,0:547]
    port4 = data[2072:*,548:*]
    
;average and sigma values for each port
    ave_sig,port1,lave1,lsig1
    ave_sig,port2,lave2,lsig2
    ave_sig,port3,lave3,lsig3
    ave_sig,port4,lave4,lsig4


;put all sigma values and average values into one array
    avepix = [lave1,lave2,lave3,lave4]
    sigpix = [lsig1,lsig2,lsig3,lsig4]

;write data to file if keyword write set
    if keyword_set(writefile) then begin
        res = readfits(file,hdrd)
        obstime = strcompress(sxpar(hdrd,'DATE_OBS'),/remove_all)
        ins = strcompress(sxpar(hdrd,'INSTRUME'),/remove_all)
        
        iris_dark_trend_fix,obstime,offsets,ins
;put data back together data into ports

        port1 = port1-offsets[0] 
        port2 = port2-offsets[1] 
        port3 = port3-offsets[2] 
        port4 = port4-offsets[3] 

        rdata = [[port1,port2],[port3,port4]]

        writefits,odir+ofil,rdata,hdrd

    endif

end

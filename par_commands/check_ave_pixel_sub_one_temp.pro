pro check_ave_pixel_sub_one_temp,file,endfile,timfile,avepix,sigpix,temps
;file is file name data is an array containing whether the ports passed or failed (1 is pass 0 is failed)
    compile_opt idl2
;    read_iris,file,index,data
;read in iris data
    read_iris,file,hdr,data

;get file time 
    splfile = strsplit(file,'/',/extract)
    endfile = splfile[n_elements(splfile) - 1]
    year  = strmid(endfile,3,4)
    month = strmid(endfile,7,2)
    day   = strmid(endfile,9,2)
    hour  = strmid(endfile,12,2)
    min   = strmid(endfile,14,2)
    sec   = strmid(endfile,16,2)
  

    timfile = year+'/'+month+'/'+day+'T'+hour+':'+min+':'+sec
;read in dark data from that day
    readcol,'../temps/'+year+month+day+'_iris_temp.fmt',date_obs,tccd1,tccd2,tccd3,tccd4,bt06,bt07,format='A,f,f,f,f,f,f',/silent,skipline=1

;   create julian day array
;    time_tab = dblarr(n_elements(date_obs))
;
;
;    for i=0,n_elements(date_obs)-1 do begin
;        timet = date_obs[i]
;        year  = fix(strmid(timet,0,4))
;        month = fix(strmid(timet,5,2))
;        day   = fix(strmid(timet,8,2))
;        hour  = fix(strmid(timet,11,2))
;        min   = fix(strmid(timet,14,2))
;        sec   = fix(strmid(timet,17,2))
;        time_tab[i] = julday(month,day,year,hour,min,sec)
;    endfor


    temp_tab = [[tccd1],[tccd2],[tccd3],[tccd4],[bt06],[bt07]]
    temp_tab = transpose(temp_tab)

   
    
;give data to iris_prep_dark subtracts off temperature and base line dark model
    iris_make_dark_one_temp,hdr,dark,temps,date_obs,temp_tab,levels

;remove calculated dark from data
    data = data-dark
    
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

end

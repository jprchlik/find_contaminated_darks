pro check_ave_pixel_sub,file,endfile,timfile,avepix,sigpix
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
    readcol,'../temps/'+year+month+day+'_iris_temp.fmt',date_obs,tccd1,tccd2,tccd3,tccd4,bt06,bt07,format='A,f,f,f,f,f,f'

    time_tab = date_obs
    temp_tab = [[tccd1],[tccd2],[tccd3],[tccd4],[bt06],[bt07]]

   
;give data to iris_prep_dark subtracts off temperature and base line dark model
    index = iris_make_dark,hdr,dark,temps,time_tab,temp_tab,levels

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

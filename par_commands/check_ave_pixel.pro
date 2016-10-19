pro check_ave_pixel,file,endfile,timfile,avepix,sigpix
;file is file name data is an array containing whether the ports passed or failed (1 is pass 0 is failed)
    compile_opt idl2
;    read_iris,file,index,data
    print,file
    fits_read,file,data,hdr
    port1 = data[0:2071,0:547]
    port2 = data[0:2071,548:*]
    port3 = data[2072:*,0:547]
    port4 = data[2072:*,548:*]
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
    
    
;average and sigma values for each port
    ave_sig,port1,lave1,lsig1
    ave_sig,port2,lave2,lsig2
    ave_sig,port3,lave3,lsig3
    ave_sig,port4,lave4,lsig4


;put all sigma values and average values into one array
    avepix = [lave1,lave2,lave3,lave4]
    sigpix = [lsig1,lsig2,lsig3,lsig4]

end

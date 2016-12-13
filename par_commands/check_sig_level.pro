pro check_sig_level,file,pass,endfile,timfile,total5,exptime
;file is file name data is an array containing whether the ports passed or failed (1 is pass 0 is failed)
    compile_opt idl2
;    read_iris,file,index,data
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
    

    
;get array of pixels greater than 5 sigma
    lsig51 = fivesigma(port1)
    lsig52 = fivesigma(port2)
    lsig53 = fivesigma(port3)
    lsig54 = fivesigma(port4)
;get total values above 5 sigma
    total5 = lsig51+lsig52+lsig53+lsig54

;return exposure time
    exptime = sxpar(hdr,'INT_TIME')

;normalize total5 by expsure time
    if exptime gt 1.0 then total5 = total5/exptime
    

;fraction to pass as good 
;   passfrac = 0.0001
;6.E-5 value comes from the Gaussian Distribution of 5 sigma
   passfrac = 6.E-5
;being a little more restrictive
;   passfrac = 3.E-5
;   passfrac = 2.E-4
;
    pass1 = float(lsig51)/n_elements(port1) lt passfrac
    pass2 = float(lsig52)/n_elements(port2) lt passfrac
    pass3 = float(lsig53)/n_elements(port3) lt passfrac
    pass4 = float(lsig54)/n_elements(port4) lt passfrac

    pass = (pass1 or pass2 or pass3 or pass4)
;fraction of pixels with sigma greater than 5 sigma normalized by exposure time
    badfrac = float(total5)/(n_elements(port1)+n_elements(port2)+n_elements(port3)+n_elements(port4))
    pass = badfrac lt passfrac

;remove wavy readouts from simonatinous readout
    if year+'/'+month eq '2014/09' then pass = 0

;Check for blanks if more than 5 in entire CCD drop port
    if n_elements(data[where(data le 0)]) gt 5 then pass = 0


;print data to output file sorted by processor
    print,endfile,' ',timfile,pass


;number of pixels in each port which have values above the 5 sigma level
;    lsig51 = sig51
;    lsig52 = sig52
;    lsig53 = sig53
;    lsig54 = sig54
  
;set pass to be the number of greater than 5 sigma pixels
;    pass = [lsig51,lsig52,lsig53,lsig54]
;    if lsig51 gt 1 then print,pass

end

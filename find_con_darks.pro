pro find_con_darks,month,yeari,sdir=sdir,simpleb=simpleb,complexa=complexa,type=type
    compile_opt idl2
;;;;;;;;;;;;;;;;;;;;;;;;;
;needs simpleb or complexa
;;;;;;;;;;;;;;;;;;;;;;;;

;look up directory structure which contain level0 darks
    if keyword_set(sdir) then sdir=sdir else sdir = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/'
    if keyword_set(simpleb) then sdir=sdir+'simpleB/'
    if keyword_set(complexa) then sdir=sdir+'complexA/' 
    if keyword_set(type) then type = type else type = 'NUV'

; find whether month is list or single value
    monarr = n_elements(size(month))
    monsin = 0
    if monarr eq 3 then begin
;month is a single value
        monsin = 1
        month = [month]
    endif

;check whether year is a single value
    yeaarr = n_elements(size(yeari))
    yeasin = 0
    if yeaarr eq 3 then begin
;yeari is a single value
        yeasin = 1
        yeari = [yeari]
    endif


;check that if year or month are arrays that their lengths are the same
    yearlen = n_elements(yeari)
    montlen = n_elements(month)
    if ((yeasin eq 0) and (monsin eq 0)) then begin
        if yearlen ne montlen then MESSAGE,'Arrays must be the same size if both Month and Year are arrays'        
    endif

;create arrays of the same size if one array is just one value
    if ((yeasin eq 0) and (monsin eq 1)) then month = month[0]+intarr(yearlen)
    if ((yeasin eq 1) and (monsin eq 0)) then yeari = yeari[0]+intarr(montlen)

;loop over all elements  arrays
    for i=0,n_elements(month)-1 do begin
        smonth = strcompress(string(month[i]),/remove_all)
        syeari = strcompress(string(yeari[i]),/remove_all)
;add extra information for short handed inputs
        if strlen(smonth) eq 1 then smonth = '0'+smonth
        if strlen(syeari) eq 2 then syeari = '20'+syeari

;check to make sure the month and year strings are the correct length
        if strlen(smonth) ne 2 then MESSAGE,'Month must be input in either DD or D'
        if strlen(syeari) ne 4 then MESSAGE,'Year must be input in either YYYY or YY'
;create full path
        fullp = sdir+syeari+'/'+smonth+'/'
;list files of specified type 
        filelist = file_search(fullp+type+'*fits')
        nFiles = n_elements(filelist)
        passarra = intarr(nFiles)
        

;list all files in current month
    ;Start a process of multithreading in IDL
        nproc = !cpu.TPOOL_NTHREADS/2
        oBridge = objarr(nproc)

        for j=0,n_elements(oBridge)-1 do begin
            oBridge[j] = obj_new('IDL_IDLBridge',$
                Callback='check_sig_levelCallback',output="log_"+strcompress(string(j),/remove_all)+".txt")
            oBridge[j].setProperty, userData=0
        endfor

;initalize threading variables
        filesProcessed = 0
        nextIndex = 0
        cpl = 0

;Multithread file list       
        while filesProcessed lt nFiles do begin
            for j=0, nproc-1 do begin
    ;Get status of loop
                oBridge[j].getProperty,userdata=status
    ;Check the status value
                switch (status) of
                    0: begin
    ;Assign the work if not yet complete
                        if nextIndex lt nFiles then begin
                            oBridge[j].setProperty, userData=1
;                            print,"check_sig_level,'"+$
;                                filelist[nextIndex]+"', pass"
;                            oBridge[j].execute,".r /Volumes/Pegasus/jprchlik/iris/find_con_darks/check_sig_level.pro",/nowait
;                            oBridge[j].execute,".r /Volumes/Pegasus/jprchlik/iris/find_con_darks/fivesigma.pro",/nowait
                            oBridge[j].execute, "check_sig_level,'"+$
                                filelist[nextIndex]+"', pass,endfile,timfile",/nowait
    ;Add 1 to next index
                            nextIndex++
                        endif
                        break
                    end
                    2: begin
    ;Store the results
                        filesProcessed++
                        cpl += oBridge[j]->getVar('pass')
                        passer = oBridge[j]->getVar('pass')
                        basicf = oBridge[j]->getVar('endfile')
                        timeou = oBridge[j]->getVar('timfile')
                        print,basicf,' ',timeou,passer
                       
                        oBridge[j].setProperty,userData=0
                        break
                    end
    ;quit if you get some other value
                    else: begin
                    end 
                endswitch
            endfor
        endwhile
            
        
;      
;
;
;
;    print,'File criteria values'
    print,syeari+'/'+smonth+' Number Pass = '+strcompress(cpl,/remove_all)+' ('+strcompress(float(cpl)/nFiles*100.,/remove_all)+'%)'
;   for j=0, nFiles-1 do print,filelist[j],cpl[j]

    endfor
;
end

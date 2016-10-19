pro dark_trend,sdir=sdir,pdir=pdir,simpleb=simpleb,logdir=logdir,outdir=outdir
;create a plot containing the average dark value as a function of time


;look up directory structure which contain level0 darks
    if keyword_set(sdir) then sdir=sdir else sdir = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/'
    if keyword_set(simpleb) then sdir=sdir+'simpleB/'
    if keyword_set(complexa) then sdir=sdir+'complexA/'
    if keyword_set(logdir) then logdir=logdir+'/' else logdir = ''
    if keyword_set(outdir) then outdir=outdir+'/' else outdir = ''

    files = strarr(1)
;get all darks from filelist with SAA data
    rmonths = file_search('../txtout/*txt')

;put all files into one array for easy threading
    for i=0,n_elements(rmonths)-1 do begin
        readcol,rmonths[i],dfile,time,pass,numb,intt,format='A,A,F,F,F',delimiter=' ',skipline=1
;only include files which pass SAA cut (i.e. a normal amount of 5 sigma pixels) and are the 0 second darks
        dfile = dfile[where((pass gt 0) and (intt < 0.5))]
        files = [files,dfile]
    endfor

;correct for empty first string
    files = files[1,*]

;Start a process of multithreading in IDL (creating objects to pass to processors)
    nproc = !cpu.TPOOL_NTHREADS/2
    oBridge = objarr(nproc)
    for j=0,n_elements(oBridge)-1 do begin
        oBridge[j] = obj_new('IDL_IDLBridge',$
            Callback='check_ave_pixelCallback',output=logdir+"log_"+strcompress(string(j),/remove_all)+".txt")
        oBridge[j].setProperty, userData=0
    endfor


;initalize threading variables
    nFiles = n_elements(files)
    filesProcessed = 0
    nextIndex = 0
    avepix = []
    sigpix = []
    timeou = strarr(1)
    basicf = strarr(1)


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
                        year = strmid(files[nextIndex],3,4)
                        month = strmid(files[nextIndex],7,2)
                        oBridge[j].setProperty, userData=1
                        oBridge[j].execute, "check_ave_pixel,'"+$
                            sdir+'/'+year+'/'+month+'/'+ $
                            files[nextIndex]+$
                            "',endfile,timfile,avepix,sigpix",/nowait
;Add 1 to next index
                        nextIndex++
                    endif
                    break
                end
                2: begin
;Store the results
                    filesProcessed++
                    basicf = [basicf,oBridge[j]->getVar('endfile')]
                    timeou = [timeou,oBridge[j]->getVar('timfile')]
                    avepix = [[avepix],[oBridge[j]->getVar('avepix')]]
                    sigpix = [[sigpix],[oBridge[j]->getVar('sigpix')]]

                    oBridge[j].setProperty,userData=0
                    break
                end
;quit if you get some other value
                else: begin
                end
            endswitch
        endfor
    endwhile

;remove first empty element from string arrays
    basicf = basicf[1:*]
    timeou = timeou[1:*]
;sort by output time
    sorter = sort(timeou)
    basicf = basicf[sorter]
    timeou = timeou[sorter]
;which be 2-D array
    for j=0,1 do begin
        avepix[j,*] = avepix[j,sorter]
        sigpix[j,*] = sigpix[j,sorter]
    endfor

;plot darks average over time
    plot_dark_trend,timeou,avepix

    


end

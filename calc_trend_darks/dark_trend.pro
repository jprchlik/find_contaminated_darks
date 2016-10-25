pro dark_trend,sdir=sdir,pdir=pdir,simpleb=simpleb,logdir=logdir,outdir=outdir
;create a plot containing the average dark value as a function of time
    compile_opt idl2


;look up directory structure which contain level0 darks
    if keyword_set(sdir) then sdir=sdir else sdir = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/'
    if keyword_set(simpleb) then sdir=sdir+'simpleB/'
    if keyword_set(complexa) then sdir=sdir+'complexA/'
    if keyword_set(logdir) then logdir=logdir+'/' else logdir = 'log/'
    if keyword_set(outdir) then outdir=outdir+'/' else outdir = 'txtout/'
    if keyword_set(pdir) then pdir=pdir+'/' else pdir='plots/'

    files = strarr(1)
;get all darks from filelist with SAA data
    rmonths = file_search('../txtout/*txt')

;put all files into one array for easy threading
    for i=0,n_elements(rmonths)-1 do begin
        readcol,rmonths[i],dfile,time,pass,numb,intt,format='A,A,F,F,F',delimiter=' ',skipline=1
;only include files which pass SAA cut (i.e. a normal amount of 5 sigma pixels) and are the 0 second darks
        dfile = dfile[where((pass gt 0) and (intt lt 0.5))]
        files = [files,dfile]
    endfor

;correct for empty first string
    files = files[1:*]



;dropping parallel functionality 
;Start a process of multithreading in IDL (creating objects to pass to processors)
;    nproc = !cpu.TPOOL_NTHREADS/2
;    oBridge = objarr(nproc)
;    for j=0,n_elements(oBridge)-1 do begin
;        oBridge[j] = obj_new('IDL_IDLBridge',$
;            Callback='check_ave_pixelCallback',output=logdir+"log_"+strcompress(string(j),/remove_all)+".txt")
;        oBridge[j].setProperty, userData=0
;    endfor


;initalize threading variables
    nFiles = n_elements(files)
    filesProcessed = 0
    nextIndex = 0
;    avepix = []
;    sigpix = []
;    timeou = strarr(1)
;    basicf = strarr(1)

;Testing purposes
;    nFiles = 45
   

;Non parallel variables
    avepix = fltarr(4,nFiles)
    sigpix = fltarr(4,nFiles)
    timeou = strarr(nFiles)
    basicf = strarr(nFiles)
    otemps = fltarr(12,nFiles)

;loop to file model subtraced dark pixel values
    for j=0,nFiles-1 do begin
        year = strmid(files[j],3,4)
        month = strmid(files[j],7,2)
;check ave pixel returns the average pixel value per dark integration minus the iris model dark, the RMS around the average, and the assumed temperatures for the background model
        check_ave_pixel_sub,sdir+'/'+year+'/'+month+'/'+files[j],endfile,timfile,avepix1,sigpix1,temps
        avepix[*,j] = avepix1
        sigpix[*,j] = sigpix1
        otemps[*,j] = temps
        basicf[j]   = endfile
        timeou[j]   = timfile
    endfor

;;Multithread file list       
;    while filesProcessed lt nFiles do begin
;        for j=0, nproc-1 do begin
;;Get status of loop
;            oBridge[j].getProperty,userdata=status
;;Check the status value
;            switch (status) of
;                0: begin
;;Assign the work if not yet complete
;                    if nextIndex lt nFiles then begin
;                        year = strmid(files[nextIndex],3,4)
;                        month = strmid(files[nextIndex],7,2)
;                        oBridge[j].setProperty, userData=1
;                        print,"check_ave_pixel_sub,'"+$
;                            sdir+'/'+year+'/'+month+'/'+ $
;                            files[nextIndex]+$
;                            "',endfile,timfile,avepix,sigpix"
;;run command
;                        oBridge[j].execute, "check_ave_pixel_sub,'"+$
;                            sdir+'/'+year+'/'+month+'/'+ $
;                            files[nextIndex]+$
;                            "',endfile,timfile,avepix,sigpix",/nowait
;;Add 1 to next index
;                        nextIndex++
;                    endif
;                    break
;                end
;                2: begin
;;Store the results
;                    filesProcessed++
;                    basicf = [basicf,oBridge[j]->getVar('endfile')]
;                    timeou = [timeou,oBridge[j]->getVar('timfile')]
;                    avepix = [[avepix],[oBridge[j]->getVar('avepix')]]
;                    sigpix = [[sigpix],[oBridge[j]->getVar('sigpix')]]
;
;                    oBridge[j].setProperty,userData=0
;                    break
;                end
;;quit if you get some other value
;                else: begin
;                end
;            endswitch
;        endfor
;    endwhile
;
;;remove first empty element from string arrays
;    basicf = basicf[1:*]
;    timeou = timeou[1:*]
;;sort by output time
;    sorter = sort(timeou)
;    basicf = basicf[sorter]
;    timeou = timeou[sorter]
;;which be 2-D array
;    for j=0,3 do begin
;        avepix[j,*] = avepix[j,sorter]
;        sigpix[j,*] = sigpix[j,sorter]
;    endfor
;create IDL save file
    save,/variables,filename='alldark_ave_sig.sav'

;plot darks average over time
    plot_dark_trend,basicf,avepix

;output file
    fname = outdir+'current_pixel_averages.txt'

;format for the header
    fformat = '(A45,2X,A25,2X,8A15)'
;format for the data
    dformat = '(A45,2X,A25,2X,8F15.2)'




   

    openw,1,fname
    printf,1,'file','time','ave1','ave2','ave3','ave4','sig1','sig2','sig3','sig4',format=fformat
    for j=0,n_elements(basicf)-1 do printf,1,basicf[j],timeou[j],avepix[0,j],avepix[1,j],avepix[2,j],$
        avepix[3,j],sigpix[0,j],sigpix[1,j],sigpix[2,j],sigpix[3,j],format=dformat
    close,1



end

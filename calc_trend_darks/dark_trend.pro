pro dark_trend,sdir=sdir,pdir=pdir,simpleb=simpleb,complexa=complexa,logdir=logdir,outdir=outdir
;create a plot containing the average dark value as a function of time
    set_plot,'Z'
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




;initalize threading variables
    nFiles = n_elements(files)
    filesProcessed = 0
    nextIndex = 0
   

;Non parallel variables
    avepix = fltarr(4,nFiles)
    sigpix = fltarr(4,nFiles)
    timeou = strarr(nFiles)
    basicf = strarr(nFiles)
    otemps = fltarr(12,nFiles)
    olevel = fltarr(3,4,nFiles)

;loop to file model subtraced dark pixel values
    for j=0,nFiles-1 do begin
        year = strmid(files[j],3,4)
        month = strmid(files[j],7,2)
;check ave pixel returns the average pixel value per dark integration minus the iris model dark, the RMS around the average, and the assumed temperatures for the background model
        check_ave_pixel_sub,sdir+'/'+year+'/'+month+'/'+files[j],endfile,timfile,avepix1,sigpix1,temps,levels,/writefile
        avepix[*,j] = avepix1
        sigpix[*,j] = sigpix1
        ;Comment out 2018/01/31 J. Prchlik
        ; Removed because after 2014 temperatures not needed
        ;Reinserted after fixing only 1 day of temperatures issue 2018/02/01
        otemps[*,j] = temps
        basicf[j]   = endfile
        timeou[j]   = timfile
        ;Comment out 2018/01/31 J. Prchlik
        ; Removed because after 2014 temperatures not needed
        ;Reinserted after fixing only 1 day of temperatures issue 2018/02/01
        olevel[0,*,j] = levels[0,*] ;Temperature polynomial 
        olevel[1,*,j] = levels[1,*] ;Dark Current 
        olevel[2,*,j] = levels[2,*] ; pedestal offset from read_iris
    endfor

;create IDL save file
    save,/variables,filename='alldark_ave_sig.sav'

;plot darks average over time
    plot_dark_trend,basicf,avepix,pplot=360.;wait 6 minutes so the plotting works(probably overkill but the cron has time

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

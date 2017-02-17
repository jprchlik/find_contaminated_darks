;+
;
; dir = target directory (on /data/alisdair/...) eg, '2014/12/SimpleB/'
; t0 - begin time for files (date_obs format)
; t1 - end time for files (date_obs format)
;      if t0 or t1 undefined, does all files in dir
; typ = 0 [before mar 2015] =1 [mar 2015 and later]
; odir = output directory  eg, 'simpb19/'
;
; SHS 09/01/15
;     09/02/15  v2 works if t0 t1 are not defined, fixed odir
; NS,SHS 09/03/15  v3 fix write out of files, and read in of later ones
;
;-

pro do_lev1to0_darks,dir,t0,t1,typ,odir

dir0='/data/alisdair/IRIS_LEVEL1_DARKS/'


fil=findfile(dir0+dir+'*.fits')
;fil=findfile('/Volumes/Pegasus/nschanch/iris/test/lev1/'+'*.fits')
read_sdo,fil,ind,d,/nod

if n_elements(t0)*n_elements(t1) ne 0 then begin
   tim0=anytim(t0)
   tim1=anytim(t1)
   tobs=anytim(ind.date_obs)
   ig=where(tobs le tim1 and tobs ge tim0,ng)
endif else begin
   ng=n_elements(fil)
   ig=indgen(ng)
endelse




if ng ne 0 then begin
   for j=0,ng-1 do begin
      filj=fil(ig(j))
      read_sdo,filj,indj,dj
      dj0=iris_lev120_darks(dj,indj)
      indj.history = 'Back converted from level1 using iris_lev1to0'
      indj.lvl_num = 0.0
      if typ eq 0 then begin
         filx=strmid(filj,strpos(filj,'iris.lev1'),strlen(filj))
         tstr=strmid(filx,10,4)+strmid(filx,15,2)+strmid(filx,18,2)
         tstr=tstr+'_'+strmid(filx,21,6)
      endif else begin
         filx=strmid(filj,strpos(filj,'iris2'),strlen(filj)) 
         tstr=strmid(filx,4,15)
      endelse
      namj=indj.instrume + tstr + '.fits'
      
      ;mwritefits,indj,dj0,outdir=odir,outfile=namj
      mwritefits,indj,dj0,outfile=odir+namj
      
      print,odir+namj+' .... written.'
   endfor
endif

return
end
;
;
;

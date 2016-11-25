pro format_for_steve

;need to produce ti,avi, and avni
    resolve_routine,'get_binned_iris_dark_trend',/COMPILE_FULL_FILE


    restore,'alldark_ave_sig.sav'

    type = ['NUV','FUV']
    ports = ['port1','port2','port3','port4']

    string_to_time,timeou,time ;convert file name to string
    
    time = time*24.*3600. ;covert JULDAY to seconds


    for i=0,n_elements(type)-1 do begin

        ccdtyp = where(strmatch(basicf,type[i]+'*',/FOLD_CASE) eq 1)

 


        get_binned_iris_dark_trend,avepix[*,ccdtyp],time[ccdtyp],gropave,gropsig,groptim

        if type[i] eq 'NUV' then begin 
            sigmx = gropsig
            fname = 'offset30n.dat'
            avni = gropave
            ti = groptim
            save,sigmx,avni,ti,filename=fname
         endif else begin
            sigmx = gropsig
            fname = 'offset30f.dat'
            avi = gropave
            ti = groptim
            save,sigmx,avi,ti,filename=fname
         endelse


    endfor


end

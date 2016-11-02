pro group_iris_darks,jime,newd,bin=bin

;jime is the julian day (assumed to be in seconds and sorted) 
;newd is the array values where the difference is greater than the given bin
;bin is the maximum difference in time to bin in days

    if keyword_set(bin) then bin=bin*24.*3600. else bin=2.5*24.*3600.
    
    
    ;find observations less than one day apart and group them
    sime = jime[indgen(n_elements(jime)-2)+1]
    eime = jime[indgen(n_elements(jime)-2)]
    
    ;find the differences from one array value to the next
    adif = sime-eime
    
    ;Set looking area to be 2.5 days different from previous value (might be too inclusive but darks are ~30 days apart)
    newd = where(adif gt bin)
    
    ;Add one to newd to offset one less elements
    newd = newd+1
    ;Add first and last element values
    newd = [0,newd,n_elements(jime)]


end

pro find_new_temps,strday,out_temps


    tempsamps = 1440 ;number of temperature samples per day
;covert input string to JULDAY
    string_to_time,strday,jime 
    jime =jime*24.*3600.
;get group array
    group_iris_darks,jime,newd
;Indcides of jime array
    indices= dindgen(n_elements(jime))
;output temperatures
    out_temps = fltarr(13,n_elements(jime))
 
; loop over group array
    for i=1,n_elements(newd)-1 do begin
        ;get the grouped subset
        subset = where((indices ge newd[i-1]) and (indices lt newd[i]))
        strsub = strmid(strday[subset],0,10)
        ;grab a subset of days for grouping for reading the temperature file
        days = strsub[uniq(strsub)]
        
        
        subtemps = fltarr(13,n_elements(days)*tempsamps)
        subdates = strarr(n_elements(days)*tempsamps)

        for j=0,n_elements(days)-1 do begin
            fday = STRJOIN(STRSPLIT(days[j],'/',/extract),'') 
            finp = '/Volumes/Pegasus/jprchlik/iris/find_con_darks/temps/'+fday+'_iris_temp.fmt'
            readcol,finp,DATE_OBS,ITF1CCD1,ITF2CCD2,ITNUCCD3,ITSJCCD4,BT06CBPX,BT07CBNX,BT10HOPA,BT17SMAP,IT01PMRF,IT03PMRA,IT04TELF,IT12HOPA,IT13FRAP,format='A,F,F',/sil
            ;store values in array for obs

            subdates[j*tempsamps:(j+1)*tempsamps-1] = DATE_OBS
            subtemps[0:12,j*tempsamps:(j+1)*tempsamps-1] = [ITF1CCD1,ITF2CCD2,ITNUCCD3,ITSJCCD4,BT06CBPX,BT07CBNX,BT10HOPA,BT17SMAP,IT01PMRF,IT03PMRA,IT04TELF,IT12HOPA,IT13FRAP]
        endfor
        ;interpolate temperatures and store in output array
        for j=0,12 do begin
            interp_temps,strday[subset],temp_int,subdates,subtemps[j,*]
            out_temps[j,subset] = temp_int
        endfor
        
    endfor



end


pro get_binned_iris_dark_trend,nyval,jime,gropave,gropsig,groptim

;nyval an array of with shape [x,y] which to group and find the average values and uncertainty  
;jime is an array of julday time converted to seconds which corresponds to the rows in nyval
;gropave is the output average value of the grouped darks
;gropsig is the output error in the mean of the grouped darks
;groptime is the output aveage time in JULDAY seconds of the observation    

    ;get dimensions for data array
    dim = size(nyval)
    
    ;get binned information
    group_iris_darks,jime,newd
    
    ;Arrays for the output data
    gropave = fltarr(dim[1],n_elements(newd))
    gropsig = fltarr(dim[1],n_elements(newd))
    groptim = dblarr(n_elements(newd))
    
    ;an array of indices
    indices = dindgen(dim[2])

    for i=1,n_elements(newd)-1 do begin
        grouparray = where((indices ge newd[i-1]) and (indices lt newd[i]))

        for j=0,3 do begin
            gropave[j,i] = mean(nyval[j,grouparray])
;use the error in the mean for the error
           gropsig[j,i] = stddev(nyval[j,grouparray])/sqrt(float(n_elements(grouparray)))
           if gropsig[j,i] gt 20 then gropsig[j,i] = 0 ;removes 1 bad point for now
       endfor
       groptim[i] = mean(jime[grouparray])

    endfor

end

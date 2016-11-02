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


pro get_binned_iris_dark_trend,nyval,jime,gropave,gropsig,groptime

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

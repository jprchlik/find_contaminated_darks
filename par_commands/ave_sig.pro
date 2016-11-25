pro ave_sig,data,ave,sig,sigl=sigl,tol=tol,verbose=verbose

    if keyword_set(sigl) then sigl=sigl else sigl = 4.
    if keyword_set(tol)  then tol = tol else tol =0.01

    sig = stddev(data)
    ave = median(data)

;test of average
    tave = 10.*tol
    while tave ge tol do begin; wait until average changes by less than 1 percent
        good = where(abs(data-ave) le sigl*sig)
        oave = ave
    
        ave = mean(data[good])
        sig = stddev(data[good])

        tave = abs(oave-ave)/abs(ave)
; if you reject as many points as the toleralence  then exit and store mean
        if float(n_elements(good))/n_elements(data) le tol then tave =0
    endwhile

    if keyword_set(verbose) then print,strcompress(n_elements(good))+' out of '+strcompress(n_elements(data))+' kept'
    

end

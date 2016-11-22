pro ave_sig,data,ave,sig,sigl=sigl

    if keyword_set(sigl) then sigl=sigl else sigl = 4.

    sig = stddev(data)
    ave = median(data)

;test of average
    tave = 1.
    while tave ge 0.01 do begin; wait until average changes by less than 1 percent
        good = where(abs(data-ave) le sigl*sig)
        oave = ave
    
        ave = mean(data[good])
        sig = stddev(data[good])

        tave = abs(oave-ave)/abs(ave)
    endwhile
    

end

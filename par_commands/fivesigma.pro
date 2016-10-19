function fivesigma,indata

;median of input data
    mindata = median(indata)
;standard deviation of input data
    stddata = stddev(indata)

;find where values are greater than 5 sigam
    wherearr = where(indata gt 5*stddata+mindata)

    output = n_elements(wherearr)

    return, output 
end 

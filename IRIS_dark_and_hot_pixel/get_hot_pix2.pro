function get_hot_pix2, index, data, deviation, med, sig
;This function returns a heat map the same dimensions as the input data.
;Each pixel of the heat map gives a count for the number of times the corresponding data pixel is identified as 'hot'
;INPUTS: index - index of the IRIS dark file
;		 data - data from the IRIS dark file
;		 deviation - the standard deviation you want to use to define a 'hot' pixel. 
;Added J. Prchlik 09/19/2016
;OUTPUTS: med - the median pixel value for a given CCD
;         sig - the sigma pixel value for a given CCD
;

dsize = size(data) ;find the dimensions of the port
heat_map = intarr(dsize[1],dsize[2]) ;create an empty array the same dimensions as the data



;STEP 1:
;This step despikes the data so you can find a meaningful median.  
bright_pixels=[]
data2 = data
for jj=0, n_elements(index)-1 do begin
	bright_pixels = where(data[*,*,jj] gt (median(data[*,*,jj]) + 5*stdev(data[*,*,jj]))) ;find the bright pixels
	intermediate = data[*,*,jj]
	intermediate[bright_pixels] = median(data[*,*,jj]) ;replace the bright pixels with the median value for that frame
;next smooth over spatial variations in the chip (J. Prchlik 2016/12/05)
    smoothed = smooth(smooth(smooth(intermediate,10,/edge_trunc),20,/edge_trunc),40,/edge_trunc)
    smoothed = smoothed-median(smoothed) ;change the median smoothed value to 0 to correct for spatial offsets

	data2[*,*,jj] = intermediate+smoothed ;coorect for spatial variations (J. Prchlik 2016/12/05)
	;heat_map[bright_pixels] = heat_map[bright_pixels]+1
endfor



;STEP 2:
;This section finds a median frame and adjusts the rest to have the same median. 
for ii = 0, n_elements(index)-1 do begin
	if ii eq 0 then med_port = median(data2[*,*,ii]) else med_port = [med_port, median(data2[*,*,ii])]
endfor

med_medport = median(med_port) ;Find the median value of the medians of each image in port 1

at_median = where(med_port eq med_medport) ; Find which images have a median the same as the overall median 
med_index = index[at_median[0]] ;Pick the first of those images to use as the standard candle.
;print, 'Median median time for this obs is: ', med_index.date_obs
diff_from_median = med_medport - med_port


;Shift everything to make the median for each image the same.
for ii=0, n_elements(diff_from_median)-1 do begin
	data[*,*,ii] = data[*,*,ii]+diff_from_median[ii]
	;print, median(data[*,*,ii])
endfor


;Add J. Prchlik 09/19/2016
;Create arrays to store the median value and sigma used by each index
med = fltarr(n_elements(data2[0,0,*]))
sig = fltarr(n_elements(data2[0,0,*]))


;STEP 3:
; Then use that 'despiked' data as the median above which hot pixels are found
for jj=0, n_elements(index)-1 do begin
;Added J. Prchlik 09/19/2016
;Store median and sigma values used in finding bright pixels
    med[jj] = median(data2[*,*,jj])
    sig[jj] = stddev(data2[*,*,jj])
	bright_pixels = where(data[*,*,jj] gt (median(data2[*,*,jj]) + deviation*stdev(data2[*,*,jj])))	;find pixels that are a given sigma above the despiked median
	;print, 'there are '+ string(n_elements(bright_pixels)) +' bright pixels'
	;data2[bright_pixels = median(data[*,*,jj])
	heat_map[bright_pixels] = heat_map[bright_pixels]+1 ;add 1 to our heat map for each pixel flagged as hot. 
endfor
;END TEST

;Return an array the size of the input data, where each pixel value is the count of the number of times that pixel was flagged hot. 
return, heat_map


end

function median_index_by_month, index, data


;this returns the index for the first image where the median is the same as the median for the overall dataset. 
;files = file_search('/data/ekhi/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/2015/01/','*.fits')
;read_iris, files, index, data ;read in all of the files
;if port eq 'port1' then fport = data[0:2071,0:547,*]


dsize = size(data) ;find the dimensions of the port
heat_map = intarr(dsize[1],dsize[2])

;First, despike the data
data = despike_data(index, data)

for ii = 0, n_elements(index)-1 do begin
	if ii eq 0 then med_port = median(data[*,*,ii]) else med_port = [med_port, median(data[*,*,ii])]
endfor

med_medport = median(med_port) ;Find the median value of the medians of each image in port 1
at_median = where(med_port eq med_medport) ; Find which images have a median the same as the overall median 
if n_elements(at_median) eq 1 then begin	
	med_index = index[at_median] ;Pick the first of those images to use as the standard candle.
	;med_data = data[at_median]
endif else begin
	med_index = index[at_median[0]]
	;med_data = median(data[*,*,at_median], dimension=3)
endelse

return, med_index


end
function despike_data, index, data


;Do a cosmic ray correction first ('despike' the data)
for jj=0, n_elements(index)-1 do begin
	bright_pixels = where(data[*,*,jj] gt (median(data[*,*,jj]) + 5*stdev(data[*,*,jj])))	
	intermediate = data[*,*,jj]
	intermediate[bright_pixels] = median(data[*,*,jj])
	data[*,*,jj] = intermediate
endfor

return, data
end
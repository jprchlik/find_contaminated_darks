pro hot_pixel_plot_wrapper, year_list=year_list, folder=folder, outdir=outdir, deviation=deviation, cutoff_list=cutoff_list, types=types, ports=ports,file_loc=file_loc
;This is the wrapper program for hot_pixel_exploration. This makes plots showing the number of hot pixels 
;	in dark calibration observations over time.
;If you only want to re-make a single plot, you can call hot_pixel_exploration directly
;
;INPUTS			- FOLDER - the file path for where the .sav files with hot pixel information live
;				- YEAR_LIST - list of years that you want to plot the data for. Default is ['2014','2015',...] to the present year
;				- OUTDIR - file path to where you want to save the plot to. Default is the current directory. 
;				- DEVIATION - the sigma value you want to use as a cutoff for hot pixels. Default is 5 sigma
;				- CUTOFF_LIST - the fraction of time above which you will define a pixel hot in a given month. Default is [0.1, 0.5, 0.9]
;				- TYPES - which CCD you want to look at. Options are FUV and NUV. Default is both
;				- PORTS - which port you want to look at. Default is all 4 (['port1','port2', 'port3','port4'])
;		        - FILE_LOC - where the level0 files are kept. Default is /data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/


;Written 2016/02/04 by N. Schanche, SAO

;'************************NEED TO CHANGE THE DEFAULT OUTDIR TO THE FILEPATH THAT ALISDAIR SET UP**********************'
if not keyword_set(outdir) then begin
	cd, current = outdir
	outdir=outdir+'/'
endif
if not keyword_set(deviation) then deviation=5
;if not keyword_set(folder) then folder='/Volumes/Churchill/nschanch/iris/Hot_pixel_sav_files/5sigma_cutoff/'
if not keyword_set(folder) then folder='Hot_pixel_sav_files/5sigma_cutoff/'

;Want to run this for every year from the start of regular darks (2014) to present

;Add file loc keyword which is contained in the IRIS_heat_map2  2018/09/17 J. Prchlik
if not keyword_set(file_loc) then file_loc = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/'

if not keyword_set(year_list) then begin
	time = systime()
	year = strmid(time, 20,4) ;current year as a string
	start_year = 2014
	end_year= fix(year) ;current year as an integer
	year_arr = indgen(end_year - start_year+1)+start_year
	year_list=strarr(n_elements(year_arr))
	for i=0, n_elements(year_arr)-1 do year_list[i] = strcompress(string(year_arr[i]),/remove_all) ;['2014','2015','2016'...] to the current year
endif


if not keyword_set(cutoff_list) then cutoff_list = [0.1, 0.5,  0.9] ;Fraction of time a pixel is above the sigma threshhold in a month. 
if not keyword_set(types) then types = ['FUV','NUV'] ;Do both CCDs
if not keyword_set(ports) then ports = ['port1','port2', 'port3','port4']

;Find the hot pixel count for each combination of port and type
for ii=0, n_elements(types)-1 do begin
	for jj=0, n_elements(ports)-1 do begin
		file_update = folder+'NEW_'+ports[jj]+'_'+types[ii]+'_hot_pixel_counts.sav'
		print, 'Updating '+file_update
		iris_heat_map2, file_update, outdir=outdir, deviation=deviation, type=types[ii], port=ports[jj],year_list=year_list,file_loc=file_loc
	endfor
endfor

;Now make a plot for the FUV and NUV
for ii=0, n_elements(types)-1 do begin
	;for jj=0, n_elements(cutoff_list)-1 do begin
	 hot_pixel_trend_plots, outdir=outdir, folder=folder, type=types[ii], year_list=year_list
;	endfor
endfor

end

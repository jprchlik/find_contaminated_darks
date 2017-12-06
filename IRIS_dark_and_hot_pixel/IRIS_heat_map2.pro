pro IRIS_heat_map2, sav_file, year_list=year_list, outdir=outdir, month_list=month_list, deviation=deviation, type=type, port=port
;This program goes through all of the dark calibration images of 0s and 30s exposure times, analyzes them for dark pixel count rates, 
;		 and appends the results to the given file.  
;INPUTS: SAV_FILE - the file you want to update (for example, '/Volumes/Churchill/nschanch/iris/hot_pixel_trends/5sigma_cutoff/NEW_port1_FUV_hot_pixel_counts.sav')
;				    If no file is specified, it will create a new one. 
;		 YEAR_LIST - an array containing the years of interest, i.e. ['2014','2015']
;		 OUTDIR - the directory you want to write to. Default is the current directory
;		 MONTH_LIST - list of the months you want to study. Default is every month, Jan-Dec
;		 DEVIATION - the sigma value you want to use as a cutoff for hot pixels. Default is 5 sigma
;		 TYPE - either 'FUV' or 'NUV'. Will prompt you if not specified. 
;		 PORT - readout port of the CCD (choices are 'port1', 'port2', 'port3', or 'port4'. Will prompt you if not specified. 
;		 FILE_LOC - where the level0 files are kept. Default is /data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/
;
;Notes:  This program is called by 'hot_pixel_plot_wrapper as an automatic update for the hot pixel plots.
;			However, it can be run by itself with the proper inputs. 
;History:Written by N. Schanche 2016/03/03
;			- Added prompts for missing keywords 2016/05/12 (N. Schanche)
;           - Added day to unique identifier, multiple dark calibrations are allowed per month 2016/09/15 (J. Prchlik)
;           - Added median and sigma arrays for tracing median dark and median sigma history 2016/09/19 (J. Prchlik)

;level0 files are currently located here at SAO: /data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/YYYY/MM/
;What months of darks are you interested in?
if not keyword_set(year_list) then year_list = ['2014','2015','2016','2017','2018'] 
if not keyword_set(month_list) then month_list = ['01','02','03','04','05','06','07','08','09','10','11','12']
if not keyword_set(deviation) then deviation = 5
if not keyword_set(identifier) then identifier = ['20000101']
if not keyword_set(type) then begin
	type=''
	read, type, prompt='You need to specify FUV or NUV: '
endif 
if not keyword_set(port) then begin
	port=''
	read, port, prompt='You need to specify the port (port1, port2, port3, or port4): '
endif 
if not keyword_set(file_loc) then file_loc = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/'
if keyword_set(sav_file) and file_test(sav_file) then restore, sav_file 

;loop through every month for each year
for ii=0, n_elements(year_list)-1 do begin
	for kk=0, n_elements(month_list)-1 do begin
		month=month_list[kk]
		
        ;Changed Jakub Prchlik 09/14/2016
        ;moved up in testing file properties
		if file_test(file_loc+year_list[ii]+'/'+month+'/') then begin ;Only do it if the files actually exist
            ;Changed Jakub Prchlik  09/14/2016
            ; Moved up 1 if statement
			files = file_search(file_loc+year_list[ii]+'/'+month+'/',type+'*.fits')
            ;Added Jakub Prchlik  09/14/2016
            ;Grabs days from fits file name string
            ;Added another identation level
            ;depend on current dark directory
            days = STRMID(files,86,2)          
            days = days[uniq(days)]
            ;Added Jakub Prchlik 09/15/2016
            ;Check for calibrations that cross days
            ;Create integer array with same number of elements as days in that month
            iday = MAKE_ARRAY(n_elements(days),/INTEGER,VALUE=1)
            ;loop over days in that month
            for pp=0,n_elements(days)-1 do begin
                ;Skip day if it has already found to be a continuation of a previous day
                if iday[pp] eq 1 then begin
                    ;loop for days that only change by 1 and remove them from day array
                    checkd = uint(days)-uint(days[pp])
                    baddou = where(checkd eq 1,counts)
                   
                    if counts gt 0 then iday[baddou] = 0
                endif
            endfor

            ;Remove 2nd observation from observations that cross a day
            iday = where(iday eq 1)
            days = days[iday]



;           days = days[uniq(days)]
            for pp=0,n_elements(days)-1 do begin
                ;Jakub Prchlik 09/14/2016
                ;Added string to indentifier
        		this_identifier = string(year_list[ii])+'_'+string(month)+'_'+days[pp]
                ;Add Jakub Prchlik 09/14/2016
                ;test for uniq dates
        		if total(strmatch(identifier, this_identifier)) eq 0 then begin ;Only do the analysis if it has not been done before. 

                    ;Added Jakub Prchlik 09/14/2016
                    ;start of string for filename
                    sfil =  type+string(year_list[ii])+string(month)+string(days[pp])
                    ;Added Jakub Prchlik 09/15/2016
                    ;Include in search plus one day
                    day1 = repstr(string(days[pp]+1,format='(I2)'),' ','0')
                    sfil1 =  type+string(year_list[ii])+string(month)+day1
			        files = file_search(file_loc+string(year_list[ii])+'/'+string(month)+'/'+sfil+'_*.fits')
			        files1 = file_search(file_loc+string(year_list[ii])+'/'+string(month)+'/'+sfil1+'_*.fits')
                    ;Added Jakub Prchlik 09/15/2016
                    ;concatenate two arrays only if the next day array has some length
                    if n_elements(files1) eq 1 then files = files else files = [files,files1]
    			;print, this_identifier 
    
    				read_iris, files, index, data ;read in all of the files
    				;cut out only the data in the specified port
    				if port eq 'port1' then fport = data[0:2071,0:547,*] 
    				if port eq 'port2' then fport = data[0:2071,548:*,*]
    				if port eq 'port3' then fport = data[2072:*,0:547,*]
    				if port eq 'port4' then fport = data[2072:*,548:*,*]
    	
    				short_exp = where(index.instrume eq type and index.int_time lt 0.5 and index.missvals lt 10) ;This should eliminate problems with missing parts of the dataset.
    				long_exp = where(index.instrume eq type and index.int_time ge 30. and index.missvals lt 10)
    				short_index = index[short_exp]
    				short_data = fport[*,*,short_exp]
    				long_index = index[long_exp]
    				long_data = fport[*,*,long_exp]
    	
    	
    				test1=[]
    				test2=[]
    				;print, n_elements(short_index), n_elements(long_index)
    
    				;the next several lines sorts out data that is very snowy and messes with the analysis
    				for jj=0, n_elements(short_index)-1 do begin
    					test1 = [test1, mean(short_data[*,*,jj])]
    				endfor
    				for jj=0, n_elements(long_index)-1 do begin
    					test2 = [test2, mean(long_data[*,*,jj])]
    				endfor
    				good0 =  where(test1 lt median(test1)*1.05) 
    				good30 =  where(test2 lt median(test2)*1.05)
    				;print, n_elements(good0), n_elements(good30)
    
    				short_index = short_index[good0]
    				short_data = short_data[*,*,good0]
    				long_index = long_index[good30]
    				long_data = long_data[*,*,good30]
    
    				dsize = size(fport) ;find the dimensions of the port
    				heat_map_0s = fltarr(dsize[1],dsize[2])
    				heat_map_30s = fltarr(dsize[1],dsize[2])
    	
    
    				;Update all of the keywords in the file. Check the function headers for more description.
    				;If reading in an existing save file, it will add to the existing keywords. If not, it will create a new one.
    				;Tot_img_XX is the total number of images in a given month that have the indicted exposure time
    				if keyword_set(tot_img_0s) then tot_img_0s = [tot_img_0s, n_elements(short_index)] else tot_img_0s = n_elements(short_index)
    				if keyword_set(tot_img_30s) then tot_img_30s = [tot_img_30s, n_elements(long_index)] else tot_img_30s = n_elements(long_index)
    
                    ; 2016/09/19 (J. Prchlik)
                    ;Added median and sigma return values 
					heat_map_0s  = get_hot_pix2(short_index, short_data, deviation, med_00, sig_00)
    				heat_map_30s = get_hot_pix2(long_index , long_data , deviation, med_30, sig_30)
    
    				if keyword_set(hot_pix_by_month_0s ) then hot_pix_by_month_0s  = [[[hot_pix_by_month_0s ]],[[reform(heat_map_0s , dsize[1],dsize[2],1)]]] else hot_pix_by_month_0s  = reform(heat_map_0s , dsize[1],dsize[2],1)
    				if keyword_set(hot_pix_by_month_30s) then hot_pix_by_month_30s = [[[hot_pix_by_month_30s]],[[reform(heat_map_30s, dsize[1],dsize[2],1)]]] else hot_pix_by_month_30s = reform(heat_map_30s, dsize[1],dsize[2],1)
                    ;2016/09/19 J. Prchlik
                    ;format so all median and sigma arrays are the same length
                    fmed_00 = fltarr(40)-9999.0
                    fmed_30 = fltarr(40)-9999.0
                    fsig_00 = fltarr(40)-9999.0
                    fsig_30 = fltarr(40)-9999.0

                    fmed_00[findgen(n_elements(med_00))] = med_00
                    fmed_30[findgen(n_elements(med_30))] = med_30                                       
                    fsig_00[findgen(n_elements(sig_00))] = sig_00                   
                    fsig_30[findgen(n_elements(sig_30))] = sig_30                   
                   

                    ;2016/09/19 (J, Prchlik)
                    ;Store median and sigma values in array
    				if keyword_set(hot_pix_med_by_month_0s)  then hot_pix_med_by_month_0s  = [[hot_pix_med_by_month_0s ],[fmed_00]] else hot_pix_med_by_month_0s  = fmed_00 
    				if keyword_set(hot_pix_med_by_month_30s) then hot_pix_med_by_month_30s = [[hot_pix_med_by_month_30s],[fmed_30]] else hot_pix_med_by_month_30s = fmed_30
    				if keyword_set(hot_pix_sig_by_month_0s)  then hot_pix_sig_by_month_0s  = [[hot_pix_sig_by_month_0s ],[fsig_00]] else hot_pix_sig_by_month_0s  = fsig_00 
    				if keyword_set(hot_pix_sig_by_month_30s) then hot_pix_sig_by_month_30s = [[hot_pix_sig_by_month_30s],[fsig_30]] else hot_pix_sig_by_month_30s = fsig_30
    
    
    				if keyword_set(median_data_by_month_0s) then median_data_by_month_0s = [[[median_data_by_month_0s]],[[reform(median_data_by_month(short_index, short_data), dsize[1],dsize[2],1)]]] else median_data_by_month_0s = reform(median_data_by_month(short_index, short_data), dsize[1],dsize[2],1)
    				if keyword_set(median_data_by_month_30s) then median_data_by_month_30s = [[[median_data_by_month_30s]],[[reform(median_data_by_month(long_index, long_data), dsize[1],dsize[2],1)]]] else median_data_by_month_30s = reform(median_data_by_month(long_index, long_data), dsize[1],dsize[2],1)
    
    				if not keyword_set(median_index_by_month_0s) then median_index_by_month_0s = []
    				index_0s_uniform = get_uniform_struct(median_index_by_month(short_index, short_data))
    				median_index_by_month_0s = [median_index_by_month_0s, index_0s_uniform]
    				if not keyword_set(median_index_by_month_30s) then median_index_by_month_30s = []
    				index_30s_uniform = get_uniform_struct(median_index_by_month(long_index, long_data))
    				median_index_by_month_30s = [median_index_by_month_30s, index_30s_uniform]
    
    				if keyword_set(norm_hot_pix_by_month_0s) then norm_hot_pix_by_month_0s = [[[norm_hot_pix_by_month_0s]],[[reform(heat_map_0s/float(n_elements(short_index)), dsize[1],dsize[2])]]] else norm_hot_pix_by_month_0s = reform(heat_map_0s/float(n_elements(short_index)))
    				if keyword_set(norm_hot_pix_by_month_30s) then norm_hot_pix_by_month_30s = [[[norm_hot_pix_by_month_30s]],[[reform(heat_map_30s/float(n_elements(long_index)), dsize[1],dsize[2])]]] else norm_hot_pix_by_month_30s = reform(heat_map_30s/float(n_elements(long_index)))
    
    				identifier = [identifier, this_identifier]
    			endif
            endfor
		endif
	endfor
endfor

if not keyword_set(outdir) then begin
	cd, current=outdir
	outdir=outdir+'/'
endif

if keyword_set(sav_file) then fname = sav_file else fname = outdir+'NEW_'+port+'_'+type+'_hot_pixel_counts.sav'
;fname = 'NEW_'+port+'_'+type+'_hot_pixel_counts.sav'

save, identifier, port, deviation, hot_pix_by_month_0s, hot_pix_by_month_30s, norm_hot_pix_by_month_0s,$
		norm_hot_pix_by_month_30s, tot_img_0s,tot_img_30s, median_data_by_month_0s, median_data_by_month_30s, $
		median_index_by_month_0s,median_index_by_month_30s,hot_pix_med_by_month_0s,hot_pix_med_by_month_30s, $
        hot_pix_sig_by_month_0s,hot_pix_sig_by_month_30s,filename=fname



end

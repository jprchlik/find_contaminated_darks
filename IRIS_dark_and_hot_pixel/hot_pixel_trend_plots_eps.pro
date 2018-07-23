pro hot_pixel_trend_plots_eps, cutoff_list=cutoff_list, folder=folder, outdir=outdir, type=type, year_list=year_list,bakeout_array=bakeout_array
;This is the program that plots the Number of Hot Pixels by month. 
;
;INPUTS -   CUTOFF_LIST - A list containing the range of cutoff ratios (times a pixel is considered hot during a dark calibration sequence for a given a month) 
;				 	 For example, a cutoff of .5 would mean that a pixel was hot in at least half of the dark frames for that month
;					 Default is [0.1,0.5,0.9]
;
;OPTIONAL INPUTS -	FOLDER: the directory in which the hot pixel count files are located
;						default is '/Volumes/Churchill/nschanch/iris/hot_pixel_trends/5sigma_cutoff/'
;					OUTDIR: the directory that you want to write the image files for the plots to.
;						default is the current working directory.
;					TYPE: either FUV or NUV. If none is set, then it plots the FUV. 
;					YEAR_LIST: List of years (as strings) you would like to include in the plot. Default is ['2014','2015']
;					CUTOFF_LIST: List of the fraction of times a pixel must be hot in a given month to be considered hot. Default is [0.1,0.5,0.9]
;					BAKEOUT_ARRAY: ARRAY of the bakeout times in Double precision JULIAN DAYS. Default is dblarr([julday(10,16,2014),julday(10,26,2015),julday(4,26,2016),julday(6,13,2018)])
;
;
;Program created by N. Schanche, SAO, Nov 2015
;Update Feb 4, 2016 - added bakeouts to the plots and to loop through the years automatically					
;device,decomposed=0,set_pixel_depth=24,set_resolution=[1000,750]
set_plot,'ps'
loadct,12

!P.THICK = 3

if not keyword_set(outdir) then begin
	cd, current = outdir
	outdir=outdir+'/'
endif

;if not keyword_set(folder) then folder='/Volumes/Churchill/nschanch/iris/Hot_pixel_sav_files/5sigma_cutoff/'
if not keyword_set(folder) then folder='/Volumes/Pegasus/jprchlik/iris/find_con_darks/IRIS_dark_and_hot_pixel/Hot_pixel_sav_files/5sigma_cutoff/'

if not keyword_set(type) then type='FUV'
;TODO: fix this so it automatically has every year since 2014. 
if not keyword_set(year_list) then year_list=['2014','2015', '2016','2017','2018']

if not keyword_set(cutoff_list) then cutoff_list=[0.1, 0.5, 0.9]

if not keyword_set(bakeout_array) then bakeout_array = double([julday(10,16,2014),julday(10,26,2015),julday(4,26,2016),julday(6,13,2018)])

for cc = 0, n_elements(cutoff_list)-1 do begin
	cutoff=cutoff_list[cc]
	ports = ['port1','port2','port3','port4']
	;Make an array 4x7 (4 ports x 7 months)
;Comment out to remove month assumption
;	hot_arr0s = intarr(4,(n_elements(year_list)*12))
;	hot_arr30s = intarr(4,(n_elements(year_list)*12))
	for ii=0, n_elements(ports)-1 do begin
	

		;restore, '/Volumes/Churchill/nschanch/iris/' + ports[ii] + '_hot_pixel_counts.sav'
		restore, folder + 'NEW_'+ports[ii] + '_' + type +'_hot_pixel_counts.sav'
		;get the normalized hot pixel counts (fraction of time each pixel is hot for each month)
		norm_hot_pix_by_month_0s_all = norm_hot_pix_by_month_0s 
		norm_hot_pix_by_month_30s_all = norm_hot_pix_by_month_30s
		;median_index_by_month_0s_all = median_index_by_month_0s
		;median_index_by_month_30s_all = median_index_by_month_30s
		;get the dates of the dark runs
		all_dates0s = median_index_by_month_0s.date_obs
		all_dates30s = median_index_by_month_30s.date_obs

        ;Added to fix month assumption (J. Prchlik 2016/12/02)
        if ii eq 0 then begin
            hot_arr0s = intarr(4,n_elements(all_dates0s))
            hot_arr30s = intarr(4,n_elements(all_dates30s))
        ;created 2D time arrays to fix offset in NUV port (2016/12/05)
	        juldays0s = dblarr(4,n_elements(all_dates0s))
	        juldays30s = dblarr(4,n_elements(all_dates30s))
        endif

	

	
		;For this loop, we are only interested in pixels that were 'hot' for at least a given percent of the images in the sequence
		img_size = size(norm_hot_pix_by_month_0s_all)



		;Goes through each month and finds which pixels are 'hot' for a given fraction of frames that month
		for jj=0, img_size[3]-1 do begin
			want0 = where(norm_hot_pix_by_month_0s_all[*,*,jj] gt cutoff)
			;print, want0
			want30 = where(norm_hot_pix_by_month_30s_all[*,*,jj] gt cutoff)
			if want0 eq [-1] then begin
				hot_arr0s[ii,jj] = 0
			endif else begin
				hot_arr0s[ii,jj] = n_elements(want0)
			endelse
			hot_arr30s[ii,jj] = n_elements(want30) ;There are always some for the 30s exposures...
			;total_hot_pix_0s[want0] = total_hot_pix_0s[want0]+1
			;total_hot_pix_30s[want30] = total_hot_pix_30s[want30]+1
			;This basically gives you an array the size of the port, with each pixel being the count
		endfor


	    ;Get the julian date, to be used to format the x-axis with the correct date
        ;Moved block inside for loop (2016/12/05 J. Prchlik)
	    for i =0, n_elements(all_dates0s)-1 do begin
	    	full_date0s = all_dates0s[i]
	    	year = strmid(full_date0s,0,4)
	    	month = strmid(full_date0s,5,2)
	    	day = strmid(full_date0s,8,2)
	    	juldays0s[ii,i] = julday(month,day,year)

	    endfor
	    for i =0, n_elements(all_dates30s)-1 do begin
	    	full_date30s = all_dates30s[i]
	    	year = strmid(full_date30s,0,4)
	    	month = strmid(full_date30s,5,2)
	    	day = strmid(full_date30s,8,2)
	    	juldays30s[ii,i] = julday(month,day,year)

	    endfor
	endfor
	dummy = label_date(date_format=['%D-%M-%Y'])
	;times0s=median_index_by_month_0s.date_obs
	;times30s=median_index_by_month_30s.date_obs


    xtick_val = double(julday(01,01,[2014,2015,2016,2017,2018]))
    xtick_str = ['2014-01','2015-01','2016-01','2017-01','2018-01']

	;Save the image as a png file. 
    for m=0,n_elements(bakeout_array)-1 do oplot, [bakeout_array[m],bakeout_array[m]],[!y.crange[0],!y.crange[1]], linestyle=2,thick=3, color=cgColor('charcoal')
	fname = outdir+'NEW_'+type+'_hot_pixel_trend_' + strtrim(string(fix(cutoff*100)),1) +'.eps'
    device,filename=fname,encap=1,/helvetica,xsize=9.0,ysize=6.0,/inch

    ;Pad in days
    daypad = 110
	;Just so the formatting looks good for the 100% cutoff case
	if cutoff eq 1. then begin
		plot, juldays0s[*,0], hot_arr0s[*,0], /nodata, Background=cgColor('white'),Color=cgColor('black'),  xstyle=1, $
			xticks=4, yrange=[-10,max(hot_arr30s)+.30*max(hot_arr30s)],ystyle=1, $
            title=type+' - Pixels hot in ' + strtrim(string(fix(cutoff*100)),1)+ '% of exposures',xtitle='Date [UTC]',ytitle='Number of Hot Pixels', $
			charthick=2,charsize=2.2,xgridstyle=1,ygridstyle=1,xticklen=1,yticklen=1,font=1, $
            xtickname=xtick_str,xtickv=xtick_val,xrange=[min(xtick_val)-daypad,max(xtick_val)+3.*daypad]
	endif else begin
		;Plot the Number of Hot Pixels vs. time
		plot, juldays0s[*,0], hot_arr0s[*,0], /nodata, Background=cgColor('white'),Color=cgColor('black'), xstyle=1, $
			xticks=4, yrange=[-10,max(hot_arr30s)+.30*max(hot_arr30s)],ystyle=1, $
            title=type+' - Pixels hot in > ' + strtrim(string(fix(cutoff*100)),1)+ '% of exposures',xtitle='Date [UTC]',ytitle='Number of Hot Pixels', $
			charthick=2,charsize=2.2,xgridstyle=1,ygridstyle=1,xticklen=1,yticklen=1,font=1, $
            xtickname=xtick_str,xtickv=xtick_val,xrange=[min(xtick_val)-daypad,max(xtick_val)+3.*daypad]

	endelse	
	;overplot the curves for the 4 different ports for both the 0s and 30s exposure files
	oplot, juldays0s[0,*], hot_arr0s[0,*], color=cgColor('blue'), thick=7, linestyle=0
	oplot, juldays0s[1,*], hot_arr0s[1,*], color=cgColor('blue'), thick=7, linestyle=5
	oplot, juldays0s[2,*], hot_arr0s[2,*], color=cgColor('blue'), thick=7, linestyle=2
	oplot, juldays0s[3,*], hot_arr0s[3,*], color=cgColor('blue'), thick=7, linestyle=4

	oplot, juldays30s[0,*], hot_arr30s[0,*], color=cgColor('red'), thick=7, linestyle=0
	oplot, juldays30s[1,*], hot_arr30s[1,*], color=cgColor('red'), thick=7, linestyle=5
	oplot, juldays30s[2,*], hot_arr30s[2,*], color=cgColor('red'), thick=7, linestyle=2
	oplot, juldays30s[3,*], hot_arr30s[3,*], color=cgColor('red'), thick=7, linestyle=4

;	oplot, juldays30s, hot_arr30s[0,*], color=cgColor('purple'), psym=6
;	oplot, juldays30s, hot_arr30s[1,*], color=cgColor('purple'), psym=6
;	oplot, juldays30s, hot_arr30s[2,*], color=cgColor('purple'), psym=6
;	oplot, juldays30s, hot_arr30s[3,*], color=cgColor('purple'), psym=6

	;Include vertical lines that represent when the bakeouts occured. These need to be manually updated for each bakeout. 
	;bakeout_time=julday(10,16,2014)
	;bakeout_time2=julday(10,26,2015)
	;bakeout_time3=julday(4,26,2016)
	;oplot, [bakeout_time,bakeout_time],[!y.crange[0],!y.crange[1]], linestyle=2,thick=7, color=cgColor('charcoal')
	;oplot, [bakeout_time2,bakeout_time2],[!y.crange[0],!y.crange[1]], linestyle=2,thick=7, color=cgColor('charcoal')
	;oplot, [bakeout_time3,bakeout_time3],[!y.crange[0],!y.crange[1]], linestyle=2,thick=7, color=cgColor('charcoal')
    ;UPdated to loop over array values and plot bakeout 2018/07/23 J. Prchlik
    for m=0,n_elements(bakeout_array)-1 do oplot, [bakeout_array[m],bakeout_array[m]],[!y.crange[0],!y.crange[1]], linestyle=2,thick=7, color=cgColor('charcoal')

    ;Include bake out label in plot legend (J. Prchlik 2016/09/26)
	labels = ['port1','port2','port3','port4','bake out']
	if cutoff lt .3 then $
        al_legend, labels, Color=['purple','purple','purple','purple',cgColor('charcoal')],thick=[3,3,3,3,3], LineStyle=[0,5,2,4,2], /right, charsize=1.5 $
    else $
        al_legend, labels, Color=['purple','purple','purple','purple',cgColor('charcoal')],thick=[3,3,3,3,3], LineStyle=[0,5,2,4,2], /left, charsize=1.5 

	;Label which are from the 30s data and which are from the 0s
	xyouts, max(juldays0s)+5, average(hot_arr30s)*1.5, '30 sec', charsize=1.5, charthick=3, color=cgColor('red')
	xyouts, max(juldays0s)+5, average(hot_arr0s)*1.5, '0 sec', charsize=1.5, charthick=3, color=cgColor('blue')
	;print, average(hot_arr30s), average(hot_arr0s)
	
    device,/close

endfor

end

pro format_hot_pix_steve, cutoff_list=cutoff_list, folder=folder, outdir=outdir, year_list=year_list
;This is the program that plots the number of hot pixels by month. 
;
;INPUTS -   CUTOFF_LIST - A list containing the range of cutoff ratios (times a pixel is considered hot during a dark calibration sequence for a given a month) 
;                    For example, a cutoff of .5 would mean that a pixel was hot in at least half of the dark frames for that month
;                    Default is [0.1,0.5,0.9]
;
;OPTIONAL INPUTS -  FOLDER: the directory in which the hot pixel count files are located
;                       default is '/Volumes/Churchill/nschanch/iris/hot_pixel_trends/5sigma_cutoff/'
;                   OUTDIR: the directory that you want to write the image files for the plots to.
;                       default is the current working directory.
;                   TYPE: either FUV or NUV. If none is set, then it plots the FUV. 
;                   YEAR_LIST: List of years (as strings) you would like to include in the plot. Default is ['2014','2015']
;                   CUTOFF_LIST: List of the fraction of times a pixel must be hot in a given month to be considered hot. Default is [0.1,0.5,0.9]
;
;
;Program created by N. Schanche, SAO, Nov 2015
;Update Feb 4, 2016 - added bakeouts to the plots and to loop through the years automatically                   
;if not keyword_set(type) then type='FUV'


if not keyword_set(outdir) then begin
    cd, current = outdir
    outdir=outdir+'/'
endif

;if not keyword_set(folder) then folder='/Volumes/Churchill/nschanch/iris/Hot_pixel_sav_files/5sigma_cutoff/'
if not keyword_set(folder) then folder='/Volumes/Pegasus/jprchlik/IRIS_dark_and_hot_pixel/Hot_pixel_sav_files/5sigma_cutoff/'

;TODO: fix this so it automatically has every year since 2014. 
if not keyword_set(year_list) then year_list=['2014','2015', '2016','2017','2018']

if not keyword_set(cutoff_list) then cutoff_list=[0.1, 0.5,0.6,0.7,0.8,0.9]

types = ['NUV','FUV']
for ll=0, 1 do begin
    type = types[ll]
    
    for cc = 0, n_elements(cutoff_list)-1 do begin
        cutoff=cutoff_list[cc]
        ports = ['port1','port2','port3','port4']
        ;Make an array 4x7 (4 ports x 7 months)
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
    
    
;        juldays0s = dblarr(n_elements(all_dates0s))
;        juldays30s = dblarr(n_elements(all_dates30s))
        ;Get the julian date, to be used to format the x-axis with the correct date
;Moved block inside loop
            for i =0, n_elements(all_dates0s)-1 do begin
                print,ii,i
                full_date0s = all_dates0s[i]
                year = strmid(full_date0s,0,4)
                month = strmid(full_date0s,5,2)
                day = strmid(full_date0s,8,2)
                juldays0s[ii,i] = julday(month,day,year)
    
            endfor
            for i =0, n_elements(all_dates0s)-1 do begin
                full_date30s = all_dates30s[i]
                year = strmid(full_date30s,0,4)
                month = strmid(full_date30s,5,2)
                day = strmid(full_date30s,8,2)
                juldays30s[ii,i] = julday(month,day,year)
    
            endfor
        endfor
        dummy = label_date(date_format=['%D-%M-%Y'])

        darkstruct = CREATE_STRUCT('JULDAY00s',juldays0s,'JULDAY30s',juldays30s,'HOT_PIX00s',hot_arr0s,'HOT_PIX30s',hot_arr30s)
        cutv = string(cutoff_list[cc],FORMAT='(F4.2)')
        save,darkstruct,filename=folder+type+'_formated_for_steve'+strcompress(cutv,/remove_all)+'.sav'
    
    endfor


endfor

end

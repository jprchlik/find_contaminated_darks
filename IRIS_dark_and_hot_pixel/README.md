IRIS Hot Pixel Calibration notes
=================================

BACKGROUND:
The IRIS CCD has many pixels that are noticeably ‘hot’, or consistently brighter than the surrounding pixels. Looking at the data, it seems that there are an increasing number of bright pixels. We (Steve Saar and Nicole Schanche) set out to determine how many pixels are affected, how serious the damage of those pixels is, how the number of affected pixels changes with time, and finally whether the pixels can be corrected. Several codes have been developed for this end. Their use is documented below.

Examples added for pulling JSOC information (09/13/2016 J. Prchlik) 
Added copy and paste example for do_lev1to0_darks (09/13/2016 J. Prchlik)
All this is now done automatically by the routine ../run_dark_checks.csh (02/17/2017 J. Prchlik)

PROGRAMS NEEDED:
do_lev1to0_darks.pro
iris_lev120_darks.pro
hot_pixel_plot_wrapper.pro
iris_heat_map2.pro
get_hot_pix2.pro
median_data_by_month.pro
median_index_by_month.pro
despike_data.pro
get_uniform_struct.pro
hot_pixel_trend_plots.pro

DATA
-------
The data used for all calculations comes from the simpleB dark calibrations performed by IRIS on a ~monthly basis. Only the 0s and 30s exposure times are considered here. To stay consistent with previous dark analysis, we make use of only the level0 data. *Note since level0 or level1 is no longer available at SAO, and we are unable to pull directly from the terminal interface of jsoc, we now have to manually download the level 1 data from the Stanford/JSOC website (http://jsoc.stanford.edu/ajax/lookdata.html, the series ID is “iris.lev1”). Note, sometimes when I order the data from JSOC, the email with the link for the data files goes to my spam folder, so you may need to look there if it seems to take too long.
The synced data (auto pulled) exists in  ‘/data/wala/darks/YYYY/MM/DD/‘
Once the appropriate level1 data is downloaded, it can be put in the following folder: ‘/data/alisdair/IRIS_LEVEL1_DARKS/YYYY/MM/simpleB/’*
The level1 data must then be back converted to level0 data. Use the following code:

Example JSOC query:
Look at calibration as ran and the time line for exact time frame  
iris.lev1[2016.08.24_06:15_TAI-2016.08.24_07:59_TAI][][? IMG_TYPE ~ "DARK" ?]   
returns ~ 150 records
Method of export should be url-tar or ftp tar for a large number of files.


N.B. This step should never be performed manually because ../run_dark_checks.csh in get_iris_darks.py


IDL> do_lev1to0_darks, dir, t0, t1, typ, odir   
where ‘dir’ is the location on /data/alisdair/IRIS_LEVEL1_DARKS/, so for example, ‘2016/02/simpleB/‘
t0 is the start time for the calibration
t1 is the end time for the calibration
typ is either 0 or 1 depending on where the files came from. If downloaded from the JSOC website, use 0. If automatically pulled, use 1. 
odir is the output directory. You should put the files in ‘/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/YYYY/MM/‘ (I need permissions, fixed on 09/13/16)
(e.g. do_lev1to0_darks,'2016/08/simpleB/',’2016-08-01 00:00:00','2016-08-31 23:59:59',0,'/Volumes/Pegasus/jprchlik/IRIS_dark_and_hot_pixel/dummydir/')
If you use a dummy directory make sure it is empty.
*Note, the magic happens with a call to <iris_lev120_darks>. This is a slightly modified file that fixes the way NUV-SJI images are de-rotated.* 


HOT PIXEL COUNTS 
-----------------

IDL>hot_pixel_plot_wrapper, year_list=year_list, folder=folder, outdir=outdir, deviation=deviation, cutoff_list   
#Need IDL 8.1 > 0 for use of NULL variable in IRIS_HEAT_MAP2.pro
This is the program that will automatically call all of the other programs you need. If you are running it by default, you don’t need to call any keywords. You will have to change the default folder, because currently it is set to look in my personal external hard drive. You will probably want a shared space. 

IDL>IRIS_heat_map2, sav_file,year_list=year_list, outdir=outdir, month_list=month_list, deviation=deviation, type=type, port=port  
#called in hot pixel wrapper
This program updates the existing save files that have information about the number of hot pixels for each exposure time, both as a raw number (hot_pix_by_month_30s) and a percent (norm_hot_pix_by_month_30s). It also contains an array with the median data values by month for each exposure (median_data_by_month_30s). It completely skips over any month it already has data for. This is a problem if there are two dark calibrations in the same month. 

IDL> get_hot_pix2, index, data, deviation   
(called in IRIS_heat_map2
 the hot pixel count is not set by YearMonthDay, therefore allows multiple hot pixel observations per month.
 It does not rely on the directory structure to do this, instead it uses the file name.
 Since the dark observation may cross a day, darks taken within one day of each other are combined to form a single point on all plots.
 this is the work horse that actually calculates the number of times each pixel is hot. It returns an array where each pixel gives a total count for times in the given calibration sequence the the pixel at that location was considered ‘hot’. If the value at that pixel is 0, that pixel’s value was always within the sigma provided. If the pixel value is 1 or 2, it was probably due to a cosmic ray hit. If the value is >2, we define it as a hot pixel. Note that the highest value can change by month. For the dark calibration sequence, there are usually ~11 images of each exposure time, but time constraints can vary that number, so it may be better to think of the value as a percent. i.e. if the value is 3 and there were 11 total images, that pixel was hot 27% of the time. 

Special note:
The program get_uniform_struct is important. The old level1 files and the new ones have different keywords that don’t play well together. I made a new structure using only keywords I use that avoids the problem. If you decide to change things in a way that needs different keywords, you will have to update this file so those keywords are saved. 

PLOTTING 
---------
IDL>hot_pixel_trend_plots, cutoff_list, outdir=outdir, folder=folder, type=type, year_list=year_list   
(Also included in hot_pixel_plot_wrapper)
This program restores the files with the naming convention ‘NEW_port1_FUV_hot_pixel_counts_2015.sav’ (generated with IRIS_heat_map2.pro) and then plots them for each percent cutoff, meaning the percentage of time a pixel must be flagged in a given month to be called hot. The decided upon cutoffs we are tracking are 10%, 50%, and 90%.

MAKING THE PLOTS ACCESSIBLE TO LMSAL

Once the plots are made, they need to be moved to a folder reachable to the outside world. This is because Lockheed will take the plots and put them on the iris webpage on the 16th of every month. 

The plots must be put into the directory
/var/www/projects/IRIS/public_html/IRIS_plots/

You must then run an rsync so it is visible to the outside. In a terminal do the following:

> /usr/bin/rsync -arHxq --delete --cvs-exclude /var/www/projects/IRIS kurasuta-dev::iris/  
Password:  
> /usr/bin/rsync -arHxq --delete --cvs-exclude /var/www/projects/IRIS kurasuta-0-0::iris/  
Password:  

I did this manually, but it is easy enough to put these commands in a single script. You may add a --password-file=FILE option to the rsync command if you wish to save you having to type the password each time. It is probably best to keep the password file in your home directory but please make sure that it is readable only by you.  
ie. chmod 700 FILE or chmod og-rwx FILE.
The outside world accesses the IRIS data at http://helio.cfa.harvard.edu/IRIS  
Once Lockheed has put them on the IRIS health and safety page, you can view them here: http://iris.lmsal.com/health-safety/longtermtrending/in_other.html  


#Long term dark analysis 
For historical (i.e. human reasons) the directory structure hides the true function of this program.
Primarily the directory now exists to test the long term trending of the IRIS pedestal dark level,
which was first noticed to be discrepant from the launch model in ~June 2014.
The main directory contains a c-shell script (run_dark_checks.csh), which runs a code series.
The code series performs the following tasks.
First, it finds the day of the observed darks by querying the google calibration-as-run calendar for IRIS dark runs in the last 25 days.
Then it grabs the text of the timeline file for that day and searches for the simpleb and complexa OBSIDs (find_dark_runs.py). 
This would run into an issue if the dark are ran on a weekend timeline (always ran on Wednesday during the time of this documentation)
or someone messed up the calibration-as-run calendar.
If it is the latter you should fix it; however, the former requires more coding or manually entering the date in to the get_dark_files.py.
Using the last set of observed dark times (set up for eclipse season, but will work in normal orbits),
the dark files are download from JSOC using the drms module (get_dark_files.py)
The code initially places the level1 dark files in /data/alisdair/IRIS_LEVEL1_DARKS/YYYY/MM/(simpleB or complexA; depending on OBSID)
and renames the files to adhere to previous standards.

Next, run_dark_checks converts the level1 files to level0 darks (do_lev1to0_darks.pro) for a given month and moves them to
the level0 directory.
Then the script checks for darks significantly affected by SAAs or CMEs (find_contaminated_darks.pro; i.e. too many 5 sigma hot pixels for a Gaussian distribution.).
Next, download the temperature files for the day darks are observed plus +/- 1 day and format the output temperature file for IDL.
Finally, compared the observed to the modeled dark pedestal trend.
(Bonus the hot_pixel_plot_wrapper is included at the end of the script and based on my directory structure.
I should just integrate into the main code because it solves a similar problem).

##run_dark_checks.csh
The c-shell file is a wrapper combining the IDL and python portions of the program.
In order to run the script from your machine you will need to do a few things.
First, is make this script executable by typing chmod a+x run_dark_checks.csh.
Then you need to update the HOME variable at the top of the directory to be your HOME directory.
Finally, you need to follow instructions at https://developers.google.com/google-apps/calendar/quickstart/python
to get google calendar API for your email address.


##find_dark_runs.py
This program requires the google calendar API referenced above,
but other than that is quite simple.
The program searches the calendar for the string calib3:darks and sends the day to get_dark_files.py and the year,month to c-shell script.

##get_dark_files.py
This program is the work horse for obtaining the darks from JSOC.
It takes the time from find_dark_runs.py and whether you are seeking complexA or simpleB darks (find_dark_runs asks for both).
The program then gets the timeline text from Lockheed, which it parses to find start and stop times for OBSIDs corresponding to the selected dark.
Next, it uses the time frame found in the timeline to query JSOC iris level1 using the drms module in python.
Once the JSOC query finishes, 
the program downloads the files and renames them according to a previous file naming convention for convince.

##do_lev1to0_darks
This is a legacy program, which uses sswidl libraries.
You may call it by the following commands in IDL.

>do_lev1to0_darks,MM,YYYY,/simpleB,'0','dummydir/'

>do_lev1to0_darks,MM,YYYY,/complexA,'0','dummydir/'

The program assumes the darks are located in /data/alisdair/IRIS_LEVEL1_DARKS/YYYY/MM,
which is why the python program downloads the files there.
The level 1 to level 0 conversion is small and mostly rotates the image using the sswidl function iris_lev120_darks.
Currently, the program is set to output to a dummy directory because saving to a network directory from IDL can 
cause hangs in my experience.
Therefore, I create the files locally then immediately move them in the script.


##find_contaminated_darks
An IDL program which finds IRIS darks contaminated by SAA or CMEs.
Must add current path to IDL_PATH in order for the program to run in parallel.
If you don't then the program will fail saying it cannot find a specified function.

The program runs by taking an array of dates, the dark file types, and channel (NUV or FUV).
You can specify the day in either 1 or 2 digits and the year in 2 or 4 digits.
If only one year is specified then all months in a month array are assumed for that year.
However, you want to span more than one year all months must be given a corresponding year array value.
Below a few valid examples:

>find_con_darks,[4,5,6,7,8,9],16,/sim,type='FUV' 
>find_con_darks,09,2016,/simpleB,type='NUV' _
>find_con_darks,[8,09],[2015,16],/sim,type='FUV' 

The program finds contaminated darks by breaking each dark image into its four ports.
Then it finds the number of pixels more than 5 sigma away from the mean.
I then sum the total number of pixels 5 sigma away from the mean and 
normalize that number by the integration time (if the integration time is greater than 1.
Then I use the pixel fraction greater than 5 sigma to find images affected by SAA.
If you assume a Gaussian distribution we would expect that fraction to be 6.E-5,
so we assume the 5 sigma Gaussian fraction to reject images with fraction higher than the Gaussian value.
Finally, the program writes the file name, start time of integration, whether it passed (1 is passed 0 is failed),
 total pixels above the 5 sigma level normalized by exposure time, and the integration time to a file.
The output file is formated NUV(or FUV)_YYYY_MM.txt.
So far the Gaussian fraction prediects 12 months are contaminated by SAAs, since the start of IRIS.

I include an example output from September, 2016, which we know is contaminated by SAA from 18:09:11 to 18:26:12.
 What we find is the SAA only contributed significantly from 18:14:49 to 18:20:52.

#2016/09 Number Pass = 68 (90.6667%)
                     file                  time    pass    total5   exptime


  NUV20160921_180506.fits   2016/09/21T18:05:06       1        20      5.02

  NUV20160921_180552.fits   2016/09/21T18:05:52       1        30     30.02

  NUV20160921_180937.fits   2016/09/21T18:09:37       1        10      0.05

  NUV20160921_180949.fits   2016/09/21T18:09:49       1         8      1.02

  NUV20160921_181006.fits   2016/09/21T18:10:06       1        26      5.02

  NUV20160921_181052.fits   2016/09/21T18:10:52       1        25     30.02

  NUV20160921_181437.fits   2016/09/21T18:14:37       1        41      0.05

  NUV20160921_181449.fits   2016/09/21T18:14:49       0       251      1.02

  NUV20160921_181506.fits   2016/09/21T18:15:06       0       207      5.02

  NUV20160921_181552.fits   2016/09/21T18:15:52       0       185     30.02

  NUV20160921_181937.fits   2016/09/21T18:19:37       0       640      0.05

  NUV20160921_181949.fits   2016/09/21T18:19:49       0      1319      1.02

  NUV20160921_182006.fits   2016/09/21T18:20:06       0       667      5.02

  NUV20160921_182052.fits   2016/09/21T18:20:52       0       260     30.02

  NUV20160921_182437.fits   2016/09/21T18:24:37       1        35      0.05

  NUV20160921_182449.fits   2016/09/21T18:24:49       1        68      1.02

  NUV20160921_182506.fits   2016/09/21T18:25:06       1        48      5.02

##temps/get_list_of_days.py
This is a simple python script, which grabs the temperature information from Lockheed.
It uses the files created by find_con_darks to find days darks were observed.
Then the program checks to make the temperature information does not exist locally,
and if it does not exist it downloads it.
Finally, it formats the file to just the important temperatures so IDL calls it easily.


##calc_trend_darks/dark_trend
The final component is the plotting of the dark trend with the average dark values for a given month overplotted.
The program to run the fix is dark_trend.pro and has a simple syntax, which specifies whether to run the trend on the simpleB 
(/simpleb) darks.
An example follows:

full:

>dark_trend,sdir=sdir,pdir=pdir,simpleb=simpleb,complexa=complexa,logdir=logdir,outdir=outdir

usual:

>dark_trend,/simpleb

The program uses the SAA free darks found previously to look in the level0 directory for darks.
Again, the program again assumes the level0 data is located on the given network drive,
but that can be changed by setting the sdir keyword.
After grouping all dark observations,
it loops over all darks computing the average and sigma values over the whole chip
in the program check_ave_pixel_sub, which is the workhorse of the program.
Upon completion of finding the averages the program calls plot_dark_trend with the after pixel values
and the observation times.
Finally, the program saves the information to .sav and .txt files (alldark_ave_sig.sav and current_pixel_averages.txt).

###par_commands/check_ave_pixel_sub.pro
This program's primary function is subtracting the current dark model from the set of darks passed to the program.
The syntax for check_ave_pixel_sub is as follows:

>check_ave_pixel_sub,file,endfile,timfile,avepix,sigpix,temps,levels,writefile=writefile

All parameters are set by default in dark_trend.pro, but for clarities sake they will be described here.
file is the full path to a given dark observation (string),
endfile is a formated file name which we will pass to plot_dark_trend (string),
timfile is the file formatted for reading the Lockheed IRIS temperature data and is computed in the program (string),
avepix is the average model subtracted dark pixel value returned by the program (4D vectory),
sigpix is the 1 sigma variation in the average value (4D vector),
temps is an array of temperatures used to derive the dark model (3x6 array),
levels is an array of dark pedestal values computed from the long term trend (4D vector),
and writefile is keyword which writes out the full dark-model dark-long term trend dark to a file. 


###calc_dark_trend/plot_dark_trend.pro
plot_dark_trend groups the average dark information and plots it as a function of time with the long term pedestal trend
overplotted.
Again everything is set by default if you use the dark_trend program,
but the keywords and syntax are as follows:

>plot_dark_trend,time,yval,sdir=sdir,pdir=pdir,rest=rest

Where time is and array of file names returned by check_ave_pixel_sub in the endfile variable,
yval is the average pixel values from check_ave_pixel_sub,
sdir is the location of the simpleb darks with time information excluded (deprecated),
pdir is the output plotting directory,
and the rest keyword allows you to restore a previously save dark save file output by dark_trend.pro (alldark_ave_sig.sav).











#Long term dark analysis 
For historical (i.e. human reasons) the directory structure hides the true function of this program.
Primarily the directory now exists to test the long term trending of the IRIS pedestal dark level,
which was first noticed to be discrepant from the launch model in ~June 2014.
The main directory contains a c-shell script (run_dark_checks.csh), which runs a code series.
The code series performs the following tasks.
First, it finds the day of the observed darks by querying the google calibration-as-run calendar for IRIS dark runs in the last 25 days.
Then it grabs the text of the timeline file for that day and searches for the simpleb and complexa OBSIDs (find_dark_runs.py). 
Using the last set of observed dark times (set up for eclipse season, but will work in normal orbits),
the dark files are download from JSOC using the drms module (get_dark_files.py)
The code initially places the level1 dark files in /data/alisdair/IRIS_LEVEL1_DARKS/YYYY/MM/(simpleB or complexA; depending on OBSID)
and renames the files to adhere to previous standards.

Next, run_dark_checks converts the level1 files to level0 darks (do_lev1to0_darks.pro) for a given month and moves them to
the level0 directory.
Then the script checks for darks significantly affected by SAAs or CMEs (find_contaminated_darks.pro; i.e. too many 5 sigma hot pixels for a Gaussian distribution.).
Next, download the temperature files for the day darks are observed plus +/- 1 day and format the output temperature file for IDL.
Finally, compared the observed to the modeled dark pedestal trend.




## find_contaminated_darks
An IDL program which finds IRIS darks contaminated by SAA or CMEs.
Must add current path to IDL_PATH in order for the program to run in parallel.
If you don't then the program will fail saying it cannot find a specified function.

The program runs by taking an array of dates, the dark file types, and channel (NUV or FUV).
You can specify the day in either 1 or 2 digits and the year in 2 or 4 digits.
If only one year is specified then all months in a month array are assumed for that year.
However, you want to span more than one year all months must be given a corresponding year array value.
Below a few valid examples:
find_con_darks,[4,5,6,7,8,9],16,/sim,type='FUV' 
find_con_darks,09,2016,/simpleB,type='NUV' _
find_con_darks,[8,09],[2015,16],/sim,type='FUV' 

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

  NUV20160921_165937.fits   2016/09/21T16:59:37       1        21      0.06

  NUV20160921_165949.fits   2016/09/21T16:59:49       1       111      1.03

  NUV20160921_170006.fits   2016/09/21T17:00:06       1        80      5.02

  NUV20160921_170052.fits   2016/09/21T17:00:52       1        35     30.02

  NUV20160921_170437.fits   2016/09/21T17:04:37       1        47      0.05

  NUV20160921_170449.fits   2016/09/21T17:04:49       1       120      1.02

  NUV20160921_170506.fits   2016/09/21T17:05:06       1        76      5.02

  NUV20160921_170552.fits   2016/09/21T17:05:52       1        47     30.02

  NUV20160921_170937.fits   2016/09/21T17:09:37       1        12      0.05

  NUV20160921_170949.fits   2016/09/21T17:09:49       1        96      1.02

  NUV20160921_171006.fits   2016/09/21T17:10:06       1        43      5.03

  NUV20160921_171052.fits   2016/09/21T17:10:52       1        32     30.02

  NUV20160921_171437.fits   2016/09/21T17:14:37       1        11      0.05

  NUV20160921_171449.fits   2016/09/21T17:14:49       1        26      1.02

  NUV20160921_171552.fits   2016/09/21T17:15:52       1        27     30.02

  NUV20160921_171937.fits   2016/09/21T17:19:37       1         4      0.05

  NUV20160921_171949.fits   2016/09/21T17:19:49       1        15      1.02

  NUV20160921_172006.fits   2016/09/21T17:20:06       1        24      5.02

  NUV20160921_172052.fits   2016/09/21T17:20:52       1        25     30.02

  NUV20160921_172437.fits   2016/09/21T17:24:37       1         4      0.05

  NUV20160921_172449.fits   2016/09/21T17:24:49       1        12      1.02

  NUV20160921_172506.fits   2016/09/21T17:25:06       1        29      5.02

  NUV20160921_172552.fits   2016/09/21T17:25:52       1        29     30.02

  NUV20160921_172937.fits   2016/09/21T17:29:37       1         9      0.05

  NUV20160921_172949.fits   2016/09/21T17:29:49       1        14      1.02

  NUV20160921_173006.fits   2016/09/21T17:30:06       1        24      5.02

  NUV20160921_173052.fits   2016/09/21T17:30:52       1        61     30.02

  NUV20160921_173437.fits   2016/09/21T17:34:37       1        13      0.05

  NUV20160921_173449.fits   2016/09/21T17:34:49       1        42      1.02

  NUV20160921_173506.fits   2016/09/21T17:35:06       1        40      5.02

  NUV20160921_173552.fits   2016/09/21T17:35:52       1        29     30.02

  NUV20160921_173937.fits   2016/09/21T17:39:37       1        28      0.05

  NUV20160921_173949.fits   2016/09/21T17:39:49       1        63      1.02

  NUV20160921_174006.fits   2016/09/21T17:40:06       1        72      5.02

  NUV20160921_174052.fits   2016/09/21T17:40:52       1        53     30.02

  NUV20160921_174437.fits   2016/09/21T17:44:37       1        99      0.05

  NUV20160921_174449.fits   2016/09/21T17:44:49       1        99      1.02

  NUV20160921_174506.fits   2016/09/21T17:45:06       1        95      5.02

  NUV20160921_174552.fits   2016/09/21T17:45:52       1        45     30.02

  NUV20160921_174937.fits   2016/09/21T17:49:37       1        31      0.05

  NUV20160921_174949.fits   2016/09/21T17:49:49       1        81      1.02

  NUV20160921_175006.fits   2016/09/21T17:50:06       1        90      5.02

  NUV20160921_175052.fits   2016/09/21T17:50:52       1        46     30.02

  NUV20160921_175437.fits   2016/09/21T17:54:37       1        26      0.05

  NUV20160921_175449.fits   2016/09/21T17:54:49       1        84      1.02

  NUV20160921_175506.fits   2016/09/21T17:55:06       1        74      5.02

  NUV20160921_175552.fits   2016/09/21T17:55:52       1        51     30.02

  NUV20160921_175937.fits   2016/09/21T17:59:37       1        14      0.05

  NUV20160921_175949.fits   2016/09/21T17:59:49       1        39      1.02

  NUV20160921_180006.fits   2016/09/21T18:00:06       1        27      5.02

  NUV20160921_180052.fits   2016/09/21T18:00:52       1        30     30.02

  NUV20160921_180437.fits   2016/09/21T18:04:37       1        16      0.05

  NUV20160921_180449.fits   2016/09/21T18:04:49       1        13      1.02

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

  NUV20160921_182552.fits   2016/09/21T18:25:52       1        34     30.02

  NUV20160921_182937.fits   2016/09/21T18:29:37       1        92      0.05

  NUV20160921_182949.fits   2016/09/21T18:29:49       1        84      1.02

  NUV20160921_183006.fits   2016/09/21T18:30:06       1        99      5.02

  NUV20160921_183052.fits   2016/09/21T18:30:52       1        69     30.02


TO GET GOOGLE API for calendar follow in instructions at https://developers.google.com/google-apps/calendar/quickstart/python

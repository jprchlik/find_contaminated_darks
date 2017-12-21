#!/bin/tcsh
#source in normal env variable from home
source $HOME/.cshrc
source $HOME/.cshrc.user

#Set up display 
#create sswidl alias
alias sswidl /proj/DataCenter/ssw/gen/setup/ssw_idl
#Setup the SSWIDL environment
# If you need to set SSW_INSTER, use the variable above. Otherwise, your 
# SSWIDL environment will not build correctly after this line.
setenv SSW /proj/DataCenter/ssw
#SSWIDL settings
#Set instrument and packages to be used after  $SSW_INSTR:
setenv SSW_INSTR    "AIA IRIS"
source $SSW/gen/setup/setup.ssw /quiet


#get printed date from dark in last 31 days
set dday=`python find_dark_runs.py`
echo ${dday}
set splt=( $dday:as/,/ / )
set iday=`echo $splt[2]/$splt[1]`
#set iday=`echo ${dday} | sed 's/,/\//g'`
#echo ${iday}

#make sure dummydir is empty
rm dummydir/*



if ($splt[1] != 'FAILED') then
    #convert level1 darks to level0 darks for simpleb
    sswidl -e "do_lev1to0_darks,'"${iday}"/simpleB/','','',0,'dummydir/'"
    mv dummydir/*fits /data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/${iday}/
    #convert level1 darks to level0 darks for complexa
    sswidl -e "do_lev1to0_darks,'"${iday}"/complexA/','','',0,'dummydir/'"
    mv dummydir/*fits /data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/complexA/${iday}/
    ##Find and remove sources with SAA or CME contamination
    sswidl -e "find_con_darks,"${dday}",type='NUV',logdir='log/',/plotter,outdir='txtout/',/sim"
    sswidl -e "find_con_darks,"${dday}",type='FUV',logdir='log/',/plotter,outdir='txtout/',/sim"
##    get the temperature values and format them
    cd temps
    python get_list_of_days.py
##    Now run so we get the current dark trend
    cd ../calc_trend_darks
    sswidl -e "dark_trend,/sim"
## format the output for steve's progam
    sswidl -e "format_for_steve"


#run the hot pixel routine when finished
    cd ../IRIS_dark_and_hot_pixel/
    sswidl -e "hot_pixel_plot_wrapper"
else echo ${dday}



endif

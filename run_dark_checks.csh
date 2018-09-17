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

#get output directory for level0 darks from the parmeter file 2018/09/17 J. Prchlik
#Two variables due to difference syntax used for shell and IDL calls
set tcsh_levz=`tail -1 parameter_file`
set sidl_levz="'"`tail -1 parameter_file`"'"


if ($splt[1] != 'FAILED') then
    #convert level1 darks to level0 darks for simpleb
    sswidl -e "do_lev1to0_darks,'"${iday}"/simpleB/','','',0,'dummydir/'"
    #Upaded move to file locaiton based on the levz definition from the parameter file (line 3) 2018/09/17 J. Prchlik
    mv dummydir/*fits ${tcsh_levz}/simpleB/${iday}/
    #convert level1 darks to level0 darks for complexa
    sswidl -e "do_lev1to0_darks,'"${iday}"/complexA/','','',0,'dummydir/'"
    #Upaded move to file locaiton based on the levz definition from the parameter file (line 3) 2018/09/17 J. Prchlik
    mv dummydir/*fits ${tcsh_levz}/complexA/${iday}/
    ##Find and remove darks with SAA or CME contamination
    #Add levz value to the sdir keyword in find_con_darks 2018/09/17 J. Prchlik
    sswidl -e "find_con_darks,"${dday}",type='NUV',logdir='log/',outdir='txtout/',/sim,sdir="${sidl_levz}
    sswidl -e "find_con_darks,"${dday}",type='FUV',logdir='log/',outdir='txtout/',/sim,sdir="${sidl_levz}
##    get the temperature values and format them
    cd temps
    python get_list_of_days.py
##    Now run so we get the current dark trend
    cd ../calc_trend_darks
    #Add levz value to the sdir keyword in find_con_darks 2018/09/17 J. Prchlik
    sswidl -e "dark_trend,/sim,sdir="${sidl_levz}
## format the output for steve's progam and the python refitting GUI
    sswidl -e "format_for_steve"


#run the hot pixel routine when finished
    cd ../IRIS_dark_and_hot_pixel/
    sswidl -e "hot_pixel_plot_wrapper,file_loc="${sidl_levz}
else echo ${dday}



endif

#!/bin/csh
#source in normal env variable from home
setenv HOME "/home/jprchlik/"
source ${HOME}.cshrc
source ${HOME}.cshrc.user
#get printed date from dark in last 31 days
set dday=`python find_dark_runs.py`
echo ${dday}
if (${dday} != '') then
##Find and remove sources with SAA or CME contamination
    sswidl -e "find_con_darks,"${dday}",type='NUV',logdir='log/',/plotter,outdir='txtout/',/sim"
    sswidl -e "find_con_darks,"${dday}",type='FUV',logdir='log/',/plotter,outdir='txtout/',/sim"
##    get the temperature values and format them
    cd temps
    python get_list_of_days.py
##    Now run so we get the current dark trend
    cd ../calc_trend_darks
    sswidl -e "dark_trend,/sim"
else echo "NO NEW DARKS"

endif

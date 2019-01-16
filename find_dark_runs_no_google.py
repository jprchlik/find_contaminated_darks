####init api to parse Google calendar for calibration-as-run for Calib3: darks
from __future__ import print_function
import os,sys
from errno import errorcode

try:
    #for python 3.0 or later
    from urllib.request import urlopen
except ImportError:
    #Fall back to python 2 urllib2
    from urllib2 import urlopen

import requests

import datetime
#get string to send to sswidl for dark files
import get_dark_files as gdf

try:
    import argparse
    #flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None


import datetime as dt




def request_dates(span=15):
    """
    Look for dark observations taken in the last span days (Default = 15).

    Parameters
    ----------
    span : int, optional
        The number of days to look for dark observations back from the current date (Default = 15).

    Returns
    -------
    dark_date: list
        The dark observations date list in YYYY/MM/DD format
    """


    #list if Days containing darks
    dark_date = []

    #Get todays date
    otime = dt.datetime.utcnow()

    #First check that any time line exists for given day
    searching = True
    sb = 0 #searching backwards days to check for dark observations
    while searching:
        #check if date contains darks
        date_str,has_darks = check_date(otime-dt.timedelta(days=sb))

        #Add to dark date list if timeline has darks
        if has_darks:
            dark_date.append(date_str)

        sb += 1 #add 1 to previous days
        if sb > span:
            searching = False #dont look back more than 9 days


    #return list of dates containing dark files
    return dark_date    




def check_date(date,irisweb='http://iris.lmsal.com/health-safety/timeline/iris_tim_archive/{2}/IRIS_science_timeline_{0}.V{1:2d}.txt'):
    """
    Check date for IRIS dark observations

    Parameters
    ----------
    date: Datetime object

    irisweb: string, optional
        A formatted text string which corresponds to the location of the IRIS timeline files 
        (Default = 'http://iris.lmsal.com/health-safety/timeline/iris_tim_archive/{2}/IRIS_science_timeline_{0}.V{1:2d}.txt').
        The {0} character string corresponds the date of the timeline uploaded in YYYYMMDD format, while {1:2d} 
        corresponds to the highest number version of the timeline, which I assume is the timeline uploaded to the spacecraft. 

    Returns
    -------
    irispath:  str
        The date being inspected in YYYY/MM/DD format

    has_darks: Boolean
        Whether timeline has dark observations or not

    """

    #Observation ID of the simple B darks
    obsid = 'OBSID=4202000003'

    #web page location of IRIS timeline
    stime = date.strftime('%Y%m%d') 
    irispath = date.strftime('%Y/%m/%d')
    
    inurl = irisweb.format(stime,0,irispath).replace(' ','0') #searching for V00 file verision
    resp = requests.head(inurl)
    #leave function if V00 is not found
    if resp.status_code != 200:
        return irispath,False 

    check = True
    v = 0 #timeline version

    #get lastest timeline version
    while check == True:
        inurl = irisweb.format(stime, v,irispath).replace(' ','0')
        resp = requests.head(inurl)
        #Get the last submitted timeline
        if resp.status_code != 200:
            check = False
            v+=-1
            inurl = irisweb.format(stime, v,irispath).replace(' ','0')
        else:
            v+=1
    #get the timeline file information for request timeline
    res = urlopen(inurl)

    #Read timeline from web
    res = res
    timeline = res.read()

    #make sure timeline is not in byte format, which happens in python3
    timeline = timeline.decode('utf-8')

    #check if the timeline has the simpleb obsid
    has_darks = obsid in timeline
    return irispath,has_darks
   


def main():
    """
    Get dark time without google calendar API because LMSAL blocks Google API requests

 
    Parameters:
    -----------
    None

    Returns:
    --------
    outc: string
        A string in YYYY,MM format. This string is used by other programs in the run_dark_checks.csh script. 
 
    """


    darkf = "processed_dark_months"
    prev = open(darkf,"r")
    check = prev.readlines()

    #Get dates which have dark observations
    events = request_dates(span=15)

    #set up so you only get the last event
    found = False
    for start in events:
        out = start.split('/')
        # do the check to make sure the files are not already processed
        checkd = out[0]+'/'+out[1]+'/'+out[2]+"\n"
        if checkd  in check: 
            sys.stdout.write('FAILED, ALREADY PROCESSED THIS MONTHS DARKS')
            outc = 1
            return outc

        #get and download simpleb darks
        darkd = gdf.dark_times(out[0]+'/'+out[1]+'/'+out[2],simpleb=True)
        darkd.run_all()
        #get and download complexa darks
        darkd = gdf.dark_times(out[0]+'/'+out[1]+'/'+out[2],complexa=True)
        darkd.run_all()

        #Create text variable in YYYY,MM format
        out = out[1]+','+out[0]
        found = True


#print MM/YYYY and add YYYY/MM/DD to dark file
    if ((found) & (outc == 0)): 
        sys.stdout.write(out)
        check.append(checkd)
        prev = open(darkf,'w')
        for k in check: prev.write(k)
        prev.close()
        outc = 0
 
    else: 
        sys.stdout.write('FAILED, NO DARKS FOUND')
        outc = 1
#        sys.exit(1)

    return outc #return output code
     


if __name__ == '__main__':
    try:
        outc = main()
    except Exception as e:
        outc = 2
        print(e)
        #sys.stdout.write(e)
    if outc > 1:
        sys.stdout.write("FAILED, likely reason is no new darks")

import os,sys
import datetime as dt
import numpy as np
import urllib2
import requests


class dark_times:


    def __init__(self,time,irisweb='http://iris.lmsal.com/health-safety/timeline/iris_tim_archive/2017/01/11/IRIS_science_timeline_{0}.V{1:2d}.txt'):


#web page location of IRIS timeline
        self.irisweb = irisweb
        self.otime = dt.datetime.strptime(time,'%Y/%m/%d')
        self.stime = self.otime.strftime('%Y%m%d')
        self.obsid = 'OBSID=4202000003'
        
    def request_files(self):


        check = True
        v = 0 #timeline version

#get lastest timeline version
        while check == True:
            inurl = self.irisweb.format(self.stime, v).replace(' ','0')
            print inurl
            resp = requests.head(inurl)
            if resp.status_code != 200: check = False 
            else: v+=1

#get the last good V value so last version of timeline
        inurl = self.irisweb.format(self.stime, v-1).replace(' ','0')
        res = urllib2.urlopen(inurl)
        self.res = res
        self.timeline = res.read()

    def get_start_end(self):

#lines with OBSID=obsid
        lines = []
        for line in self.timeline.split('\n'):
            if self.obsid in line:
                 lines.append(line)

#get the last set of OBSIDs (only really useful for eclipse season)
        self.sta_dark = lines[-3][3:20]
        self.end_dark = lines[-1][3:20]
            
    

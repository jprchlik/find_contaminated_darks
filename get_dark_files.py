import os,sys
import datetime as dt
import numpy as np
import urllib2
import requests


class dark_times:


    def __init__(self,time,irisweb='http://iris.lmsal.com/health-safety/timeline/iris_tim_archive/IRIS_science_timeline_{0}.V{1:2d}.txt',simpleb=True,complexa=False):


#web page location of IRIS timeline
        self.irisweb = irisweb.replace('IRIS',time+'/IRIS')
        self.otime = dt.datetime.strptime(time,'%Y/%m/%d')
        self.stime = self.otime.strftime('%Y%m%d')

        if complexa:
            self.obsid = 'OBSID=4203400000'
        if simpleb:
            self.obsid = 'OBSID=4202000003'
        
    def request_files(self):


        check = True
        v = 0 #timeline version

#get lastest timeline version
        while check == True:
            inurl = self.irisweb.format(self.stime, v).replace(' ','0')
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

        self.sta_dark_dt = self.create_dt_object(self.sta_dark)
        self.end_dark_dt = self.create_dt_object(self.end_dark)

        self.sta_dark_dt = self.sta_dark_dt-dt.timedelta(minutes=1)
        self.end_dark_dt = self.end_dark_dt+dt.timedelta(minutes=1)

#create datetime objects using doy in timeline
    def create_dt_object(self,dtobj):
        splt = dtobj.split(':')
        obj = dt.datetime(int(splt[0]),1,1,int(splt[2]),int(splt[3]))+dt.timedelta(days=int(splt[1])-1) #convert doy to datetime obj
        return obj
            
#set up JSOC query for darks
    def dark_query(self):
        from sunpy.net import jsoc
        client = jsoc.JSOCClient()
        fmt = '%Y.%m.%d_%H:%M'
        self.qstr = 'iris.lev1[{0}_TAI-{1}_TAI][][? IMG_TYPE ~ "DARK" ?]'.format(self.sta_dark_dt.strftime(fmt),self.end_dark_dt.strftime(fmt)) 
        #setup string to pass write to sswidl for download
        fmt = '%Y-%m-%dT%H:%M:%S'
        self.response = client.query(jsoc.Time(self.sta_dark_dt.strftime(fmt),self.end_dark_dt.strftime(fmt)),jsoc.Series('iris.lev1'),
                                jsoc.Notify('jakub.prchlik@cfa.harvard.edu'),jsoc.Segment('image'))
  
        self.get_darks(client)

    def get_darks(self,client):
        
        import time
        wait = True

        request = client.request_data(self.response)
        waittime = 60.*5. #five minute wait to check on data completion
        time.sleep(waittime) #

        while wait:
            stat = client.check_request(request)
            if stat == 1:
                temp.sleep(waittime)
            elif stat == 0:
                wait = False
            elif stat > 1:
                break #jump out of loop if you get an error
        #make the download directory
        bdir = '/data/alisdair/IRIS_LEVEL1_DARKS/{0}/simpleB/'.format(self.otime.strftime('%Y/%m'))
        try:
            os.makedirs(bdir)
        except OSError:
            time.sleep(1)
 
        #download the data
        res = client.get_request(request,path=bdir,progress=True)
        res.wait()

#run to completion

    def run_all(self):
        self.request_files()
        self.get_start_end()
        self.dark_query()

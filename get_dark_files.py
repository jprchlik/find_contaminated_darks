import os,sys
import datetime as dt
import numpy as np
import urllib2
import requests
from multiprocessing import Pool
import drms
from shutil import move
import glob


class dark_times:


    def __init__(self,time,irisweb='http://iris.lmsal.com/health-safety/timeline/iris_tim_archive/{2}/IRIS_science_timeline_{0}.V{1:2d}.txt',simpleb=False,complexa=False,tol=50):


#web page location of IRIS timeline

        self.irisweb = irisweb #.replace('IRIS',time+'/IRIS')
        self.otime = dt.datetime.strptime(time,'%Y/%m/%d')
        self.stime = self.otime.strftime('%Y%m%d')
        self.complexa = complexa
        self.simpleb = simpleb
#Minimum number of dark files reqiured to run
        self.tol = tol

        if complexa:
            self.obsid = 'OBSID=4203400000'
        if simpleb:
            self.obsid = 'OBSID=4202000003'
        
    def request_files(self):

#First check that any time line exists for given day
        searching = True
        sb = 0 #searching backwards days to correct for weekend or multiday timelines
        while searching:
#look in iris's timeline structure
            self.stime =  (self.otime-dt.timedelta(days=sb)).strftime('%Y%m%d')
            irispath = (self.otime-dt.timedelta(days=sb)).strftime('%Y/%m/%d')
            inurl = self.irisweb.format(self.stime,0,irispath).replace(' ','0') #searching for V00 file verision
            resp = requests.head(inurl)
#leave loop if V00 is found
            if resp.status_code == 200: searching =False
            else: sb += 1 #look one day back if timeline is missing
            if sb >= 9: 
                searching = False #dont look back more than 9 days
                sys.stdout.write('FAILED, IRIS timeline does not exist')#printing this will cause the c-shell script to fail too
                sys.exit(1) # exit the python script
            
        check = True
        v = 0 #timeline version

#get lastest timeline version
        while check == True:
            inurl = self.irisweb.format(self.stime, v,irispath).replace(' ','0')
            resp = requests.head(inurl)
            if resp.status_code != 200: 
                check = False 
                v+=-1
                inurl = self.irisweb.format(self.stime, v,irispath).replace(' ','0')
            else: v+=1
#get the timeline file information for request timeline
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
#use drms module to download from JSOC (https://pypi.python.org/pypi/drms)
        client = drms.Client(email='jakub.prchlik@cfa.harvard.edu',verbose=False)
        fmt = '%Y.%m.%d_%H:%M'
        self.qstr = 'iris.lev1[{0}_TAI-{1}_TAI][][? IMG_TYPE ~ "DARK" ?]'.format(self.sta_dark_dt.strftime(fmt),self.end_dark_dt.strftime(fmt)) 
        self.expt = client.export(self.qstr)
        #setup string to pass write to sswidl for download
###        fmt = '%Y-%m-%dT%H:%M:%S'
###        self.response = client.query(jsoc.Time(self.sta_dark_dt.strftime(fmt),self.end_dark_dt.strftime(fmt)),jsoc.Series('iris.lev1'),
###                                jsoc.Notify('jakub.prchlik@cfa.harvard.edu'),jsoc.Segment('image'))
###  
        self.get_darks(client)

    def get_darks(self,client):
        
####        import time
####        wait = True
####
####        request = client.request_data(self.response)
####        waittime = 60.*5. #five minute wait to check on data completion
####        time.sleep(waittime) #
####
####        while wait:
####            stat = client.check_request(request)
####            if stat == 1:
####                temp.sleep(waittime)
####            elif stat == 0:
####                wait = False
####            elif stat > 1:
####                break #jump out of loop if you get an error
        #make the download directory
        if self.simpleb:
            self.bdir = '/data/alisdair/IRIS_LEVEL1_DARKS/{0}/simpleB/'.format(self.otime.strftime('%Y/%m'))
            self.ldir = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/simpleB/{0}/'.format(self.otime.strftime('%Y/%m'))
        else:
            self.bdir = '/data/alisdair/IRIS_LEVEL1_DARKS/{0}/complexA/'.format(self.otime.strftime('%Y/%m'))
            self.ldir = '/data/alisdair/opabina/scratch/joan/iris/newdat/orbit/level0/complexA/{0}/'.format(self.otime.strftime('%Y/%m'))

        # check to make sure directory does not exist 
        if not os.path.exists(self.bdir):
            os.makedirs(self.bdir)
        #also make level0 directory
        if not os.path.exists(self.ldir):
            os.makedirs(self.ldir)

        #get number of records
        try:
            index = np.arange(np.size(self.expt.urls.url))
            if index[-1] < self.tol: #make sure to have at least 50 darks in archive before downloading
                sys.stdout.write("FAILED, LESS THAN {0:2d} DARKS IN ARCHIVE".format(self.tol))
                sys.exit(1)
 
        except: #exit nicely if no records exist 
            sys.stdout.write("FAILED, No JSOC record exists")
            sys.exit(1)

#check to see if darks are already downloaded Added 2017/03/20
        if len(glob.glob(self.bdir+'/*')) < self.tol:
            #Dowloand the data using drms in par. (will fuss about mounted drive ocassionaly)
            for ii in index: self.download_par(ii)
#DRMS DOES NOT WORK IN PARALELL 
####        pool = Pool(processes=4)
####        outf = pool.map(self.download_par,index)
####        pool.close()
###        self.expt.download(bdir,1,fname_from_rec=True)
 
        #download the data
####        res = client.get_request(request,path=bdir,progress=True)
####        res.wait()
#
    def download_par(self,index):
# get file from JSOC
        outf = self.expt.download(self.bdir,index,fname_from_rec=True)
#format output file 
        fils = str(outf['download'].values[0])
        fils = fils.split('/')[-1]
        nout = fils[:14]+'-'+fils[14:16]+'-'+fils[16:24]+fils[26:]
#create new file name in same as previous format
        move(str(outf['download'].values[0]),self.bdir+nout)

   


#run to completion
    def run_all(self):
        self.request_files()
        self.get_start_end()
        self.dark_query()

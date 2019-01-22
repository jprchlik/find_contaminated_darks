import datetime as dt
import glob
import numpy as np
try:
    #for python 3.0 or later
    from urllib.request import urlopen
except ImportError:
    #Fall back to python 2 urllib2
    from urllib2 import urlopen

import os
from format_temps import format_file

files = glob.glob('../txtout/*txt')

for i in files:

    x = np.loadtxt(i,dtype={'names':('file','time','pass','fivsig','exptime'),'formats':('S35','S20','i1','i4','f8')},skiprows=2)


    time = x['time'].astype('S10')

    utime = np.unique(time)
    for p in utime: 
        for j in np.arange(-2,2):
            day = dt.datetime.strptime(p.decode('utf-8'),'%Y/%m/%d')+dt.timedelta(days=int(j))
            t = day.strftime('%Y%m%d')

            fname= '{0}_iris_temp.txt'.format(t)
            if os.path.isfile(fname):
                continue
            else:
               res = urlopen('http://www.lmsal.com/~boerner/iris/temps/{0}'.format(fname))
               dat = res.read()
               fo = open(fname,'w')
               fo.write(dat)
               fo.close()
               format_file(fname)



    
   







import numpy as np
import jdcal
from datetime import datetime,timedelta
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit
from scipy.io import readsav
from fancy_plot import fancy_plot





class fit_dark:

    def __init__(self,ptype='nuv',startd=datetime(1979,1,1,0,0,0),jdate=datetime(2012,1,1,0,0,0),show=False,cut=False,fit=True):
        self.ptype = ptype.lower()
        self.startd = startd
        self.show = show
        self.jdate = (jdate-startd).total_seconds()
        self.cut = cut
        self.fit = fit

        self.gdict = {}
        #conversion from idl to python is {0,3,2,1,4,5,6,7}
        self.gdict['fuv1'] = [ 0.13676  , 0.57852  ,  3.4355e+07 , 0.11199     , 0.53048  ,  2.337e-08   ,  6.981e-16   , -0.35432 ]
        self.gdict['fuv2'] = [ 0.26720  , 0.37567  ,  3.1565e+07 , 0.20045     , 0.89111  ,  2.868e-08   ,  4.003e-16   , -0.56086 ]
        self.gdict['fuv3'] = [ 1.50775  , 0.31094  ,  3.1505e+07 , 1.71743     , -0.12981 ,  2.169e-08   ,  1.319e-15   , -0.37175 ]
        self.gdict['fuv4'] = [ 0.23718  , 0.35511  ,  3.1155e+07 , 0.18892     , 0.86652  ,  1.398e-08   ,  1.091e-15   , -0.40907 ]
        self.gdict['nuv1'] = [ 0.55083  , 0.32558  ,  3.1788e+07 , 0.54792     , -0.08227 ,  3.116e-09   ,  2.823e-16   , -0.13231 ]
        self.gdict['nuv2'] = [ 0.71724  , 0.32991  ,  3.1847e+07 , 0.69646     , 0.92275  ,  1.788e-09   ,  3.599e-16   , -0.15109 ]
        self.gdict['nuv3'] = [ 0.26202  , 0.32890  ,  3.1702e+07 , 0.25259     , 0.91326  ,  9.521e-09   ,  3.424e-16   , -0.09947 ]
        self.gdict['nuv4'] = [ 0.41113  , 0.31998  ,  3.1648e+07 , 0.45427     , 0.90299  ,  6.874e-09   ,  3.887e-16   , -0.16182 ]
        
     #   self.gdict['fuv1']=np.array([0.163    ,   0.397 ,3.18e+07    ,  0.0800   ,  0.259  ,  2.25e-08   ,  7.60e-16   , -0.3232  ])
     #   self.gdict['fuv2']=np.array([0.257    ,   0.355 ,3.11100e+07 ,   0.230   ,  0.890  ,  2.81e-08   ,  3.47e-16   , -0.4723 ])
     #   self.gdict['fuv3']=np.array([1.26100  ,  0.332  ,3.16500e+07 ,   1.43500 , -0.107  ,  3.20e-08   ,  9.57e-16   , -0.6785 ])
     #   self.gdict['fuv4']=np.array([ 0.219   ,    0.385, 3.15e+07   ,    0.175  ,  0.95500,  1.507e-08  ,  1.066e-15  , -0.4582])
     #   self.gdict['nuv1']=np.array([0.419    ,   0.2756,  3.135e+07 ,  0.4955   , -0.161  ,  2.893e-09  ,  6.71e-17   , -0.0459519 ])
     #   self.gdict['nuv2']=np.array([0.526    ,  0.270  ,  3.125e+07 ,  0.615    ,  0.824  , -5.479e-12  ,  1.345e-16  ,  0.0387826  ])
     #   self.gdict['nuv3']=np.array([  0.217  ,  0.370  ,   3.208e+07,     0.233 ,  0.983  ,  8.427e-09  ,  2.004e-16  , -0.0533 ])
     #   self.gdict['nuv4']=np.array([ 0.362   ,   0.3027,   3.144e+07,   0.437   ,  0.859  ,  4.73155e-09,  3.67756e-16, -0.04390  ])

        self.t0dict =  {}
       # self.t0dict['fuv1'] = 1.089e9
       # self.t0dict['fuv2'] = 1.089e9
       # self.t0dict['fuv3'] = 1.089e9
       # self.t0dict['fuv4'] = 1.089e9
       # self.t0dict['nuv1'] = 1.089e9 
       # self.t0dict['nuv2'] = 1.089e9
       # self.t0dict['nuv3'] = 1.089e9
       # self.t0dict['nuv4'] = 1.089e9
        self.t0dict['fuv1'] = 1090654728.
        self.t0dict['fuv2'] = 1089963933.
        self.t0dict['fuv3'] = 1090041516.
        self.t0dict['fuv4'] = 1090041516.
        self.t0dict['nuv1'] = 1090037115. 
        self.t0dict['nuv2'] = 1090037115.
        self.t0dict['nuv3'] = 1090037185.
        self.t0dict['nuv4'] = 1090037185.

        self.dtq0 = {}
        self.dtq0['fuv'] = 5.e7
        self.dtq0['nuv'] = 7.e7


    #function to fit
    def offset(self,dt0,amp1,phi1,p1,amp2,phi2,trend,quad,off):
        c = 2.*np.pi
        dtq = dt0-self.dtq0[self.ptype]
        dtq[dtq < 0.] = 0.
        return (amp1*np.sin(c*(dt0/p1+phi1)))+(amp2*np.sin(c*(dt0/(p1/2.)+phi2)))+(trend*(dt0))+(quad*(dtq**2.))+(off)
    def var_amp_offset(self,dt0,amp1,phi1,p1,amp2,phi2,trend,quad,off):
        c = 2.*np.pi
        return (amp1*np.sin(c*(dt0/p1+phi1)))+(amp2*np.sin(c*(dt0/(p1/2.)+phi2)))+(trend*(dt0))+(quad*(dt0**2.))+(off)

    #main program loop
    def main(self):
        ptype = self.ptype
    #format name of file to read
        fname = 'offset30{0}.dat'.format(ptype[0].lower())
     
    #read in trend values for given ccd
        dat = readsav(fname)
#correct for different variable name formats
        aval = '' 
        if self.ptype.lower() == 'nuv': aval = 'n'
    #put readsav arrays in defining variables
        time = dat['t{0}i'.format(aval)] #seconds since Jan. 1st 1979
        port = dat['av{0}i'.format(aval)]
        errs = dat['sigmx']

        #cut spurious point from fit
        if self.cut:
            good, = np.where((time <= 1.175e+09) | (time >= 1.180e+09))
            time = time[good]
            port = port[good,:]
            errs = errs[good,:]
    
          
        print '      {0:10},{3:10},{2:15},{1:10},{4:10},{5:20},{6:20},{7:10}'.format('Amp1','Phi1','P1','Amp2','Phi2','Trend','Quad','Offset')
    #loop over all ports
        for i in range(port.shape[1]):
           toff = self.t0dict['{0}{1:1d}'.format(ptype.lower(),i+1)] 
           dt0 = time - toff#- 31556926.#makes times identical to the values taken in iris_trend_fix

# init parameter guesses
           guess = self.gdict['{0}{1:1d}'.format(ptype.lower(),i+1)]
#fit with initial guesses
           if self.fit: popt, pcov = curve_fit(self.offset,dt0,port[:,i],p0=guess,sigma=errs[:,i]) 
           else: popt = guess
           #print '{0} {1:1d}'.format(self.ptype.upper(),i+1)
           if self.fit: print '{8}{9:1d}=[{0:^10.5f},{3:^10.5f},{2:^15.4e},{1:^10.5f},{4:^10.5f},{5:^20.9e},{6:^20.9e},{7:^10.5f}]'.format(popt[0],popt[1],popt[2],popt[3],popt[4],popt[5],popt[6],popt[7],self.ptype,i+1)
           fig, ax = plt.subplots()
           ptim = np.linspace(dt0.min(),dt0.max()+1e3,500)
           #print dt0.max()
           #print self.offset(dt0.max(),*popt)
           #print self.offset(1.2041407e8,*popt)
           ptime = [self.startd+timedelta(seconds=j+toff) for j in ptim]
           dt1 = [self.startd+timedelta(seconds=j) for j in time] 
           ax.set_title('{0} {1:1d}'.format(self.ptype.upper(),i+1))
           ax.plot(ptim,self.offset(ptim,*popt),'r--',label='fit')
           ax.scatter(dt0,port[:,i],color='black')
           ax.errorbar(dt0,port[:,i],yerr=errs[:,i],color='black',fmt='o')


           if self.fit:
               var = np.sqrt(np.sum((port[:,i]-self.offset(dt0,*popt))**2.)/float(dt0.size))
           else:
               var = np.sqrt(np.sum((port[:,i]-self.offset(dt0,*guess))**2.)/float(dt0.size))
           ax.text(dt0.min(),8,r'$\sigma$(fit) = {0:6.5f}'.format(var))
           ax.set_ylim([-5.,15.])
           ax.set_xlabel('Epoch Time [s]',fontsize=18)
           ax.set_ylabel('Counts [ADU]',fontsize=18)
           fancy_plot(ax)
    
   #        plt.show()
           fig.savefig('plots/new_fits/{0}_port{1:1d}.png'.format(self.ptype,i+1),bbox_pad=.1,bbox_inches='tight')
           if self.show: plt.show()
    
        

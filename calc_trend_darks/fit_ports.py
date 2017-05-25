import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit
from scipy.io import readsav
from fancy_plot import fancy_plot





class fit_dark:

    def __init__(self,ptype='nuv'):
        self.ptype = ptype
        self.gdict = {}
        self.gdict['fuv1']=np.array([0.163 ,  0.0800 ,3.18e+07 ,   0.397  ,  0.259, 2.25e-08,  7.60e-16  , -0.3232  ])
        self.gdict['fuv2']=np.array([0.257 ,   0.230 ,3.11100e+07 ,   0.355  ,  0.890, 2.81e-08,   3.47e-16  , -0.4723 ])
        self.gdict['fuv3']=np.array([1.26100  ,   1.43500 ,3.16500e+07  ,  0.332   ,-0.107 ,3.20e-08,   9.57e-16  , -0.6785 ])
        self.gdict['fuv4']=np.array([ 0.219,    0.175, 3.15e+07,    0.385 ,   0.95500,  1.507e-08,   1.066e-15  , -0.4582])
        self.gdict['nuv1']=np.array([0.419 ,  0.4955,  3.135e+07,   0.2756,   -0.161,  2.893e-09,     6.71e-17,  -0.0459519 ])
        self.gdict['nuv2']=np.array([0.526,  0.615,  3.125e+07,  0.270,  0.824, -5.479e-12,     1.345e-16,    0.0387826  ])
        self.gdict['nuv3']=np.array([  0.217,     0.233,   3.208e+07,  0.370,  0.983,  8.427e-09,      3.004e-16,   -0.0533 ])
        self.gdict['nuv4']=np.array([ 0.362,   0.437,   3.144e+07,   0.3027,  0.859,  4.73155e-09,     3.67756e-16,   -0.04390  ])

        self.t0dict =  {}
        self.t0dict['fuv1'] = 1090654728.
        self.t0dict['fuv2'] = 1089963933.
        self.t0dict['fuv3'] = 1090041516.
        self.t0dict['fuv4'] = 1090041516.
        self.t0dict['nuv1'] = 1090037115. 
        self.t0dict['nuv2'] = 1090037115.
        self.t0dict['nuv3'] = 1090037185.
        self.t0dict['nuv4'] = 1090037185.

        self.dtq0 = {}
        self.dtq0['fuv'] = 0.e7
        self.dtq0['nuv'] = 0.e7


    #function to fit
    def offset(self,dt0,amp1,phi1,p1,amp2,phi2,trend,quad,off):
        c = 2.*np.pi
        dtq = dt0.copy()
        dtq[dt0 < self.dtq0[self.ptype]] = 0.0 #start quad term later
        return amp1*np.sin(c*(dt0/p1+phi1))+amp2*np.sin(c*(dt0/(p1/2.))+phi2)+trend*dt0+quad*dtq**2.+off
    

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
        time = dat['t{0}i'.format(aval)]
        port = dat['av{0}i'.format(aval)]
        errs = dat['sigmx']
    
    #loop over all ports
        for i in range(port.shape[1]):
           toff = t0dict['{0}{1:1d}'.format(ptype.lower(),i+1)] 
           dt0 = time - toff

# init parameter guesses
           guess = self.gdict['{0}{1:1d}'.format(ptype.lower(),i+1)]
#fit with initial guesses
           popt, pcov = curve_fit(self.offset,dt0,port[:,i],p0=guess,sigma=errs[:,i]) 
           print '{0} {1:1d}'.format(self.ptype.upper(),i+1)
           print '{0:10}{1:10}{2:15}{3:10}{4:10}{5:15}{6:15}{7:10}'.format('Amp1','Phi1','P1','Amp2','Phi2','Trend','Quad','Offset')
           print '{0:^10.5f}{1:^10.5f}{2:^15.4e}{3:^10.5f}{4:^10.5f}{5:^15.4e}{6:^15.4e}{7:^10.5f}'.format(popt[0],popt[1],popt[2],popt[3],popt[4],popt[5],popt[6],popt[7])
           fig, ax = plt.subplots()
           ptim = np.linspace(dt0.min(),dt0.max()+1e3,1000)
           ax.set_title('{0} {1:1d}'.format(self.ptype.upper(),i+1))
           ax.plot(ptim+toff,self.offset(ptim,*popt),'r--',label='fit')
           ax.scatter(time,port[:,i],color='black')
           ax.errorbar(time,port[:,i],yerr=errs[:,i],color='black',fmt='o')
           ax.set_xlabel('Epoch Time [s]',fontsize=18)
           ax.set_ylabel('Counts [ADU]',fontsize=18)
           fancy_plot(ax)
           fig.savefig('plots/new_fits/{0}_port{1:1d}.png'.format(self.ptype,i+1),bbox_pad=.1,bbox_inches='tight')
    
        

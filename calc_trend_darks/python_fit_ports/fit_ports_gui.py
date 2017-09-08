
import matplotlib
#Use TkAgg backend for plotting 
matplotlib.use('TkAgg',warn=False,force=True)


from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
#implement the deault mpl key bindings
from matplotlib.backend_bases import key_press_handler,MouseEvent
import tkMessageBox as box
import tkFileDialog as Tkf
import numpy as np
import sys
import matplotlib.pyplot as plt
from datetime import datetime
from scipy.optimize import curve_fit


#check the python version to use one Tkinter syntax or another
if sys.version_info[0] < 3:
    import Tkinter as Tk
else:
    import tkinter as Tk



class gui_dark(Tk.Frame):

    def __init__(self,parent):
        Tk.Frame.__init__(self,parent,background='white') #create initial frame with white background

        #dictionary of initial Guess parameters (Manually update with the previous version of trend fix 
        self.gdict = {}
        #conversion from idl iris_make_dark to python is {0,1,2,3,4,5,6,7}
        self.gdict['fuv1'] = [ 0.13676  , 0.11199     ,  3.4355e+07 , 0.57852  , 0.53048  ,  2.337e-08   ,  6.981e-16   , -0.35432 ]
        self.gdict['fuv2'] = [ 0.26720  , 0.20045     ,  3.1565e+07 , 0.37567  , 0.89111  ,  2.868e-08   ,  4.003e-16   , -0.56086 ]
        self.gdict['fuv3'] = [ 1.50775  , 1.71743     ,  3.1505e+07 , 0.31094  , -0.12981 ,  2.169e-08   ,  1.319e-15   , -0.37175 ]
        self.gdict['fuv4'] = [ 0.23718  , 0.18892     ,  3.1155e+07 , 0.35511  , 0.86652  ,  1.398e-08   ,  1.091e-15   , -0.40907 ]
        self.gdict['nuv1'] = [ 0.55083  , 0.54792     ,  3.1788e+07 , 0.32558  , -0.08227 ,  3.116e-09   ,  2.823e-16   , -0.13231 ]
        self.gdict['nuv2'] = [ 0.71724  , 0.69646     ,  3.1847e+07 , 0.32991  , 0.92275  ,  1.788e-09   ,  3.599e-16   , -0.15109 ]
        self.gdict['nuv3'] = [ 0.26202  , 0.25259     ,  3.1702e+07 , 0.32890  , 0.91326  ,  9.521e-09   ,  3.424e-16   , -0.09947 ]
        self.gdict['nuv4'] = [ 0.41113  , 0.45427     ,  3.1648e+07 , 0.31998  , 0.90299  ,  6.874e-09   ,  3.887e-16   , -0.16182 ]


        #dictionary of time offsets (i.e. start times in IDL anytim format)
        self.t0dict =  {}
        self.t0dict['fuv1'] = 1090654728.
        self.t0dict['fuv2'] = 1089963933.
        self.t0dict['fuv3'] = 1090041516.
        self.t0dict['fuv4'] = 1090041516.
        self.t0dict['nuv1'] = 1090037115. 
        self.t0dict['nuv2'] = 1090037115.
        self.t0dict['nuv3'] = 1090037185.
        self.t0dict['nuv4'] = 1090037185.

        #dictionary of when to start the quadratic term for the fit
        self.dtq0 = {}
        self.dtq0['fuv'] = 5.e7
        self.dtq0['nuv'] = 7.e7

        #basic set of keys
        self.b_keys = sorted(self.gdict.keys())
        #add min and max parameters (Default no restriction)
        for i in self.b_keys:
            self.gdict[i+'_min'] = [-np.inf]*len(self.gdict[i])
            self.gdict[i+'_max'] = [ np.inf]*len(self.gdict[i])

        #list for parameters in order
        self.plis = ['Amp1','Amp2','P1','Phi1','Phi2','Trend','Quad','Offset']

        #create parent variable
        self.parent = parent

#Start the creation of the window and GUI
        self.centerWindow()
        self.FigureWindow()
        self.initUI()
        self.iris_dark_set()
        self.iris_dark_plot()



#Create area and window for figure
    def FigureWindow(self):
#set the information based on screen size
        x =  self.parent.winfo_screenwidth()
        y =  self.parent.winfo_screenheight()


        irisframe = Tk.Frame(self)

        aratio = float(x)/float(y)
#Create the figure
        self.f,self.a = plt.subplots(ncols=2,figsize=(8*aratio,8*aratio*.5),sharey=True)
#Separate the two plotting windows fuv and nuv
        self.wplot = {}
        self.wplot['fuv'] = self.a[0]
        self.wplot['nuv'] = self.a[1]

        #set title and axis labels
        for i in self.wplot.keys(): 
            self.wplot[i].set_title(i.upper())
            self.wplot[i].set_xlabel('Offset Time [s]')
            self.wplot[i].set_ylabel('Pedestal Offset [ADU]')
   

#Create window for the plot
        self.canvas = FigureCanvasTkAgg(self.f,master=self)
#Draw the plot
        self.canvas.draw()
#Turn on matplotlib widgets
        self.canvas.get_tk_widget().pack(side=Tk.TOP,fill=Tk.BOTH,expand=1)
#Display matplotlib widgets
        self.toolbar = NavigationToolbar2TkAgg(self.canvas,self)
        self.toolbar.update()
        self.canvas._tkcanvas.pack(side=Tk.TOP,fill=Tk.BOTH,expand=1)


        irisframe.pack(side=Tk.TOP)


#Create window in center of screen
    def centerWindow(self):
        self.w = 1800
        self.h = 1200
        sw = self.parent.winfo_screenwidth()
        sh = self.parent.winfo_screenheight()

        self.x = (sw-self.w)/2
        self.y = (sh-self.h)/2
        self.parent.geometry('%dx%d+%d+%d' % (self.w,self.h,self.x,self.y))


#Initialize the GUI
    def initUI(self):
#set up the title 
        self.parent.title("FIT IRIS DARK PEDESTAL")

#create frame for parameters
        frame = Tk.Frame(self,relief=Tk.RAISED,borderwidth=1)
        frame.pack(fill=Tk.BOTH,expand=1)

        self.pack(fill=Tk.BOTH,expand=1)

#set up print, refit, and quit buttons
        quitButton = Tk.Button(self,text="Quit",command=self.onExit)
        quitButton.pack(side=Tk.RIGHT,padx=5,pady=5)
        printButton = Tk.Button(self,text="Print",command=self.Print)
        printButton.pack(side=Tk.RIGHT,padx=5,pady=5)
        refitButton = Tk.Button(self,text="Refit",command=self.refit)
        refitButton.pack(side=Tk.RIGHT,padx=5,pady=5)


        #list of port to refit
        self.refit_list = []
        #set up check boxes for which ports to refit
        self.check_box = {}
        for i in self.b_keys:
            self.check_box[i+'_val'] = Tk.IntVar()
            self.check_box[i] = Tk.Checkbutton(master=self,text=i.upper(),variable=self.check_box[i+'_val'],onvalue=1,offvalue=0,command=self.refit_list_com)
            self.check_box[i].pack(side=Tk.LEFT,padx=5,pady=5)

        #dictionary containing variable descriptors 
        self.dscr = {}
        #dictionary of variables containing the Tkinter values for parameters
        self.ivar = {}

        #create column for list
        for c,i in enumerate(self.plis): 
            #crate FUV descriptors 
            Tk.Label(frame,textvariable=Tk.StringVar(value=i),height=1,width=5).grid(row=0,column=c+2)
            #crate NUV descriptors 
            Tk.Label(frame,textvariable=Tk.StringVar(value=i),height=1,width=5).grid(row=0,column=c+5+len(self.plis))

        #top left (FUV) descriptor
        Tk.Label(frame,textvariable=Tk.StringVar(value='PORT'),height=1,width=5).grid(row=0,column=0)
        #top NUV descriptor which is two after the length of the parameters array
        Tk.Label(frame,textvariable=Tk.StringVar(value='PORT'),height=1,width=5).grid(row=0,column=len(self.plis)+3)
        #Add a column to separate  NUV and FUV
        Tk.Label(frame,textvariable=Tk.StringVar(value='  '),height=1,width=5).grid(row=0,column=len(self.plis)+2)
       # loop over string containing all the gdict keys (i.e. port names)
        for m,i in enumerate(self.b_keys):
            txt = Tk.StringVar()
            txt.set(i.upper())

            #If NUV Put in the second column
            if 'nuv' in i:  
                r = int(i.replace('nuv',''))-1
                col = len(self.gdict[i])+3
            #If FUV put in the first column
            else:
                col = 0
                r = int(i.replace('fuv',''))-1
     
            #create min and max labels
            self.dscr[i+'_min'] = Tk.Label(frame,textvariable=Tk.StringVar(value='min'),height=1,width=5).grid(row=3*r+1,column=col+1)
            self.dscr[i+'_med'] = Tk.Label(frame,textvariable=Tk.StringVar(value='med'),height=1,width=5).grid(row=3*r+2,column=col+1)
            self.dscr[i+'_max'] = Tk.Label(frame,textvariable=Tk.StringVar(value='max'),height=1,width=5).grid(row=3*r+3,column=col+1)

            #Text Describing the particular port
            self.dscr[i] = Tk.Label(frame,textvariable=txt,height=1,width=5).grid(row=3*r+1,column=col)
           
            
            #loop over all columns (parameters) for each port
            for c,j in enumerate(self.gdict[i]):
                inp_val = Tk.StringVar(value='{0:10}'.format(j))
                inp_max = Tk.StringVar(value='{0:10}'.format(self.gdict[i+'_max'][c]))
                inp_min = Tk.StringVar(value='{0:10}'.format(self.gdict[i+'_min'][c]))
   
                #create input text
                self.ivar[i+'_'+self.plis[c]+'_min'] = Tk.Entry(frame,textvariable=inp_min,width=12)
                self.ivar[i+'_'+self.plis[c]+'_med'] = Tk.Entry(frame,textvariable=inp_val,width=12)
                self.ivar[i+'_'+self.plis[c]+'_max'] = Tk.Entry(frame,textvariable=inp_max,width=12)

                #place on grid
                self.ivar[i+'_'+self.plis[c]+'_min'].grid(row=3*r+1,column=c+col+2)
                self.ivar[i+'_'+self.plis[c]+'_med'].grid(row=3*r+2,column=c+col+2)
                self.ivar[i+'_'+self.plis[c]+'_max'].grid(row=3*r+3,column=c+col+2)

                #bind input to return event
                self.ivar[i+'_'+self.plis[c]+'_min'].bind("<Return>",self.iris_param)
                self.ivar[i+'_'+self.plis[c]+'_med'].bind("<Return>",self.iris_param)
                self.ivar[i+'_'+self.plis[c]+'_max'].bind("<Return>",self.iris_param)


    #Update parameters in gdict base on best fit values
    def iris_param(self,onenter):
        #release cursor from entry box and back to the figure
        #needs to be done otherwise key strokes will not work
        self.f.canvas._tkcanvas.focus_set()

       # loop over string containing all the gdict keys (i.e. port names)
        for m,i in enumerate(self.b_keys):
            #loop over all parameters and update values
            for c,j in enumerate(self.gdict[i]):
               self.gdict[i][c] = float(self.ivar[i+'_'+self.plis[c]+'_med'].get()) 
               self.gdict[i+'_min'][c] = float(self.ivar[i+'_'+self.plis[c]+'_min'].get()) 
               self.gdict[i+'_max'][c] = float(self.ivar[i+'_'+self.plis[c]+'_max'].get()) 


    #Update shown parameters base on new best fit
    def iris_show(self):
       # loop over string containing all the gdict keys (i.e. port names)
        for m,i in enumerate(self.b_keys):
            #loop over all parameters and update values
            for c,j in enumerate(self.gdict[i]):
               self.ivar[i+'_'+self.plis[c]+'_med'].delete(0,'end')

               #set formatting based on output value
               if abs(self.gdict[i][c]) < .001:
                   dfmt = '{0:10.5e}'
               elif abs(self.gdict[i][c]) > 10000.:
                   dfmt = '{0:10.1f}'
               else:
                   dfmt = '{0:10.5f}'

               #update in text box
               self.ivar[i+'_'+self.plis[c]+'_med'].insert(0,dfmt.format(self.gdict[i][c]))


         
    #set up data for plotting 
    def iris_dark_set(self):
        from scipy.io import readsav
        #Possible types of IRIS ports
        ptype = ['fuv','nuv']

        #colors associated with each port
        colors = ['red','blue','teal','black']
        #symbols associated with each port
        symbol = ['o','s','D','^']
    #format name of file to read
        self.fdata = {}
        for i in ptype: 
            fname = '../offset30{0}.dat'.format(i.lower()[0])
            #read in trend values for given ccd
            dat = readsav(fname)
            #correct for different variable name formats
            aval = '' 
            if i == 'nuv': aval = 'n'
            #put readsav arrays in defining variables
            time = dat['t{0}i'.format(aval)] #seconds since Jan. 1st 1979
            port = dat['av{0}i'.format(aval)]
            errs = dat['sigmx']


            #loop over all ports
            for j in range(port.shape[1]):
                toff = self.t0dict['{0}{1:1d}'.format(i.lower(),j+1)] 
                dt0 = time - toff#- 31556926.#makes times identical to the values taken in iris_trend_fix
                #store in dictionary [time,measured value, 1 sigma uncertainty]
                self.fdata['{0}{1:1d}'.format(i,j+1)] = [dt0,port[:,j],errs[:,j],colors[j],symbol[j]]

    #plot the best fit data
    def iris_dark_plot(self):
        #clear the plot axes 
        for i in self.wplot.keys(): 
            self.wplot[i].clear()
            self.wplot[i].set_title(i.upper())
            self.wplot[i].set_xlabel('Offset Time [s]')
            self.wplot[i].set_ylabel('Pedestal Offset [ADU]')


        #best fit lines
        self.bline = {}
        #data scatter
        self.sdata = {}
       
        #plot data for all IRIS dark remaining pedestals
        for i in self.fdata.keys():
            #Get plot associated with each port
            ax = self.wplot[i[:-1]] 
            #Put data in temp array
            dat = self.fdata[i]

            #set ptype attribute for curvefit and offset model 
            self.ptype = i[:-1]

            #get variance in best fit model
            var = self.get_var(i,self.gdict[i])
            #get offset in last data point
            last = self.get_last(i,self.gdict[i])

            #Uploaded best fit
            #current dark time plus a few hours
            ptim = np.linspace(self.fdata[i][0].min(),self.fdata[i][0].max()+1e3,500)
            #plot values currently in gdict for best fit values (store in dictionary for updating line)
            self.bline[i] = self.wplot[i[:-1]].plot(ptim,self.offset(ptim,*self.gdict[i]),color=self.fdata[i][3],label='{0}(Unc.) = {1:3.2f}'.format(i,var)) 

            #plot each port
            self.sdata[i] = ax.scatter(dat[0],dat[1],color=dat[3],marker=dat[4],label='{0}(last) = {1:3.2f}'.format(i,last))
            ax.errorbar(dat[0],dat[1],yerr=dat[2],color=dat[3],fmt=dat[4],label=None)
 

        #add legend
        for i in self.wplot.keys():
            self.wplot[i].legend(loc='upper left',frameon=False)

        self.canvas.draw()


    #get variance in the model
    def get_var(self,port,parm):
        var = np.sqrt(np.sum((self.fdata[port][1]-self.offset(self.fdata[port][0],*parm))**2.)/float(len(self.fdata[port][0])))
        return var
    #get variance in the model
    def get_last(self,port,parm):
        last = np.sqrt(((self.fdata[port][1]-self.offset(self.fdata[port][0],*parm))**2.))[-1]
        return last

    #plot the currently used best fit line
    def bfit(self,port):
        self.bline[port]


    #Pedestal offset model
    def offset(self,dt0,amp1,amp2,p1,phi1,phi2,trend,quad,off):
        c = 2.*np.pi
        dtq = dt0-self.dtq0[self.ptype]
        #do not add quadratic term before start time
        dtq[dtq < 0.] = 0.
        return (amp1*np.sin(c*(dt0/p1+phi1)))+(amp2*np.sin(c*(dt0/(p1/2.)+phi2)))+(trend*(dt0))+(quad*(dtq**2.))+(off)


    #print data to terminal
    def Print(self):
        print '      {0:10},{1:10},{2:15},{3:10},{4:10},{5:20},{6:20},{7:10}'.format('Amp1','Amp2','P1','Phi1','Phi2','Trend','Quad','Offset')
        for i in self.b_keys:
            print '{0}=[{1:^10.5f},{2:^10.5f},{3:^15.4e},{4:^10.5f},{5:^10.5f},{6:^20.9e},{7:^20.9e},{8:^10.5f}]'.format(i,*self.gdict[i])


    #refit list
    def refit_list_com(self):
        self.f.canvas._tkcanvas.focus_set()
        #check which boxes are checked 
        for i in self.b_keys:
            #if checked and not in list update the list 
            if ((self.check_box[i+'_val'].get() == 1) and (i not in self.refit_list)):
                self.refit_list.append(i)
            #if checked and already in the list continue 
            elif ((self.check_box[i+'_val'].get() == 1) and (i in self.refit_list)):
                continue
            #if not checked remove from list and deselect
            elif ((self.check_box[i+'_val'].get() == 0) and (i in self.refit_list)):
                self.refit_list.remove(i)
                self.check_box[i].deselect()
            #if not checked and not in list do nothing
            else: continue

    #Refit the model
    def refit(self):
        #refit for every model in refit list
        for i in self.refit_list:
            guess = self.gdict[i]
            mins  = self.gdict[i+'_min']
            maxs  = self.gdict[i+'_max']
            dt0   = self.fdata[i][0]
            port  = self.fdata[i][1]
            errs  = self.fdata[i][2]
            self.ptype = i[:-1]
            popt, pcov = curve_fit(self.offset,dt0,port,p0=guess,sigma=errs,bounds=(mins,maxs)) 


 
            #temporary line plot
            ptim = np.linspace(self.fdata[i][0].min(),self.fdata[i][0].max()+1e3,500)
            t_line, = self.wplot[i[:-1]].plot(ptim,self.offset(ptim,*popt),'--',color=self.fdata[i][3]) 
            self.canvas.draw()
           
            #get model variance 
            old_var = self.get_var(i,self.gdict[i])
            new_var = self.get_var(i,popt)

            #Ask if you should update the new parameter for a given fit
            if box.askyesno('Update','Should the Dark Trend Update for {0} (dashed line)?\n $\sigma$(old,new) = ({1:3.2f},{2:3.2f})'.format(i.upper(),old_var,new_var)):
                                      
                #update with new fit values
                self.gdict[i] = popt

            #remove temp line
            t_line.remove()
            self.canvas.draw()
        
        #update parameters in the box
        self.iris_show()
        #update plots
        self.iris_dark_plot()
            


#Exits the program
    def onExit(self):
       plt.clf()
       plt.close()
       self.quit()
       self.parent.destroy()




#Tells Why Order information is incorrect
    def onError(self):
        if self.error == 1:
            box.showerror("Error","File Not Found")
        if self.error == 4:
            box.showerror("Error","Value Must be an Integer")
        if self.error == 6:
            box.showerror("Error","File is not in Fits Format")
        if self.error == 10:
            box.showerror("Error","Value Must be Float")
        if self.error == 20:
            box.showerror("Error","Must Select Inside Plot Bounds")

#main loop
def main():
    global root
    root = Tk.Tk()
    app = gui_dark(root)
    root.mainloop()


if __name__=="__main__":
#create root frame
   main()

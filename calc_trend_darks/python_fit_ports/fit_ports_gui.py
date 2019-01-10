
import matplotlib
matplotlib.rcParams['font.size'] = 8

#Use TkAgg backend for plotting 
matplotlib.use('TkAgg',warn=False,force=True)


from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
#implement the deault mpl key bindings
from matplotlib.backend_bases import key_press_handler,MouseEvent
import numpy as np
import sys
import matplotlib.pyplot as plt
from datetime import datetime
from scipy.optimize import curve_fit
from fancy_plot import fancy_plot


#check the python version to use one Tkinter syntax or another
if sys.version_info[0] < 3:
    import Tkinter as Tk
    import tkMessageBox as box
    import tkFileDialog as Tkf
    import tkFont
else:
    import tkinter as Tk
    from tkinter import messagebox as box
    from tkinter import filedialog as Tkf
    from tkinter import font as tkFont



class gui_dark(Tk.Frame):

    def __init__(self,parent):
        """
        Program to fit the long term evolution of the IRIS pedestal. Hopefully this program is static and you can run the GUI with the following command:
        tcsh>python fit_ports_gui.py

        However, there will be times when this code should be modified. For example, following a prolonged bake out like the one from June 13-15, 2018.
        In that case the code modification will still be small and the exact functions you will need to edit will be specified below.


        The one thing you will need to change every time you preform a model dark pedestal recalibration is the initial_parameters.txt file in this
        directory. This file contains 9 lines. The first line is the Comma sepearated parameter header. The header information matters because it 
        is read by this GUI and used to create parameter list you see below the plots in the GUI and the "Freeze Par." check boxes. The next lines are
        the values for each parameter, comma separated, for each port, specified on the left. The GUI will read those parameters from the file and 
        create the long term trend on the plot and set the value in median text box for each parameter. The reason the file is formatted this way
        is that the iris_dark_trend_fix.pro expects the parameters in this format, so you can copy and paste the values from initial_parameters.txt
        into the newest version of iris_dark_trend_fix.pro. See the README at 
        https://github.com/jprchlik/find_contaminated_darks/tree/master/calc_trend_darks/python_fit_ports for detailed information on refitting a 
        model. This page includes video examples on refitting model parameters.


        Now if you are ever unfortunate enough to have to redefine the IRIS dark pedestal model, then you will need to make a few modifications to 
        this code. Fortunately, you will not have to add the new parameter names in manually because that is done automatically by the list of 
        parameters in the header of initial_parameters.txt. You will need to change the offset function in this module. The reason for this
        is the code needs to know how to handle to new parameters you are giving it. You will need to also add the new variable names and 
        values to the Print function in this module. The reason you have to add the Print explicitly is I do not know a priori the best format
        for printing whatever variable you add. After you bend those two short funcitons to your will, no further modifications of the
        code are needed.

        """
        Tk.Frame.__init__(self,parent,background='white') #create initial frame with white background

        #dictionary of initial Guess parameters (Manually update with the previous version of trend fix 
        self.gdict = {}

        #create a variable which switch to true after creating a plot once
        self.lat_plot = False

        #input guess file
        gfile = open('initial_parameters.txt','r')

        #read input parameters from file
        for i,line in enumerate(gfile):
           
            #remove whitespace and brackets
            line = line.replace(' ','').replace('[','').replace(']','')
            #Use the header to label all the columns
            if i == 0: self.plis=line.split(',')
            #else read in parameters
            else:
                sline = line.split('=')
                #create parameter lis for dictionary input
                self.gdict[sline[0]] = [float(j) for j in sline[1].split(',')]
       
   

        #list for parameters in order
        #self.plis = ['Amp1','Amp2','P1','Phi1','Phi2','Trend','Quad','Offset']

        #close parameter file
        gfile.close()

        #dictionary of time offsets (i.e. start times in IDL anytim format)
        self.t0dict = {}
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

        #dictionary of when to end the quadratic term for the fit
        self.dtq1 = {}
        #Turn off quadratic turn off 2018/05/25 J. Prchlik
        #Clearly does not work. Need to just flatten the term 2018/05/25 J. Prchlik
        self.dtq1['fuv'] = 1.295e8
        #Update nuv = fuv (2018/01/30) J. Prchlik
        self.dtq1['nuv'] = 1.295e8
        #self.dtq1['nuv'] = 1.131e8

        #Add the June 13-15th bake out to the dropped pedestal level
        #unit s from 1-jan-1958 based on anytim from IDL 
        self.bojune152018 = 1.2450240e+09

        #Add non-standard telescope operations following IRIS coarse control
        #From Oct. 28 - Dec. 15 2018 (Added 2019/01/10 J. Prchlik)
        self.nsdec152018  = 1.2608352e+09

        #basic set of keys
        self.b_keys = sorted(self.gdict.keys())
        #add min and max parameters (Default no restriction)
        for i in self.b_keys:
            self.gdict[i+'_min'] = [-np.inf]*len(self.gdict[i])
            self.gdict[i+'_max'] = [ np.inf]*len(self.gdict[i])

        #set up initial dictionary of guesses
        self.idict = self.gdict.copy()

        #initialize scaling limit variable
        self.sc_limit = None

        #add parameter code corresponding to position
        self.p_code = {}
        for j,i in enumerate(self.plis):
            self.p_code['{0:1d}'.format(j)] = i

        #add P2 for testing
        #self.plis = ['Amp1','Amp2','P1','P2','Phi1','Phi2','Trend','Quad','Offset']

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
        """
        This function creates a GUI window with a given size and format

        Args
        ------
        self: class
            The GUI class in this module
   
        Returns
        --------
            None
        """

#set the information based on screen size
        x =  self.parent.winfo_screenwidth()
        y =  self.parent.winfo_screenheight()


        irisframe = Tk.Frame(self)

        aratio = float(x)/float(y)
#Create the figure
        self.f,self.a = plt.subplots(ncols=2,figsize=(8*aratio,8*aratio*.25),sharex=True)
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
        """
        This function sets the size of the GUI window based on the screen size. Can cause problems for small screens.

        Args
        ------
        self: class
            The GUI class in this module
   
        Returns
        --------
            None
        """
        self.w = 1800/1
        self.h = 1200/1
        sw = self.parent.winfo_screenwidth()
        sh = self.parent.winfo_screenheight()

        self.h = self.w*float(sh)/float(sw)

        self.x = (sw-self.w)/2
        self.y = (sh-self.h)/2
        #self.parent.geometry('%dx%d+%d+%d' % (self.w,self.h,self.x,self.y))
        self.parent.geometry('%dx%d+0+0' % (sw,sh))


#Initialize the GUI
    def initUI(self):
        """
        This function initializes the GUI. This includes creating an appropriately sized GUI, adding buttons to the GUI, adding parameter text
        boxes and values, adding freeze check boxes, and adding refit check boxes.

        Args
        ------
        self: class
            The GUI class in this module
   
        Returns
        --------
            None
        """
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
        resetButton = Tk.Button(self,text="Reset",command=self.reset)
        resetButton.pack(side=Tk.RIGHT,padx=5,pady=5)

        #set up percent variation box (maximum allowed variation in parameters)
        inp_lab_per = Tk.Label(self,textvariable=Tk.StringVar(value='% Range'),height=1,width=10)
        inp_lab_per.pack(side=Tk.RIGHT,padx=5,pady=5)

        inp_val_per = Tk.StringVar(value='{0:10}'.format(np.inf))
        self.val_per = Tk.Entry(self,textvariable=inp_val_per,width=12)
        self.val_per.bind("<Return>",self.set_limt_param)
        self.val_per.pack(side=Tk.RIGHT,padx=1,pady=5)
 


        #list of port to refit
        self.refit_list = []

        #set up check boxes for which ports to refit
        self.check_box = {}
        for i in self.b_keys:
            self.check_box[i+'_val'] = Tk.IntVar()
            self.check_box[i] = Tk.Checkbutton(master=self,text=i.upper(),variable=self.check_box[i+'_val'],onvalue=1,offvalue=0,command=self.refit_list_com)
            self.check_box[i].pack(side=Tk.LEFT,padx=5,pady=5)

        #set up box showing which parameters to freeze
        inp_lab_per = Tk.Label(self,textvariable=Tk.StringVar(value='Freeze Checked Par. = '),height=1,width=20)
        inp_lab_per.pack(side=Tk.LEFT,padx=5,pady=5)

        #list of parameters to freeze
        self.freeze_list = []
        #set up check boxes for which parameter to freeze
        self.freeze_box = {}
        for i in self.plis:
            self.freeze_box[i+'_val'] = Tk.IntVar()
            self.freeze_box[i] = Tk.Checkbutton(master=self,text=i.upper(),variable=self.freeze_box[i+'_val'],onvalue=1,offvalue=0,command=self.freeze_list_com)
            self.freeze_box[i].pack(side=Tk.LEFT,padx=5,pady=5)


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
                self.ivar[i+'_'+self.plis[c]+'_min'].bind("<Return>",self.get_iris_param)
                self.ivar[i+'_'+self.plis[c]+'_med'].bind("<Return>",self.get_iris_param)
                self.ivar[i+'_'+self.plis[c]+'_max'].bind("<Return>",self.get_iris_param)


    #update the port values in the GUI
    def update_port_vals(self):  
       """
       This function updates the parameter text in the GUI based on the parameter in the gdict class. 
       This function will call after you refit a parameter and accept the new parameter values.

       Args
       ------
       self: class
           The GUI class in this module
   
       Returns
       --------
           None
       """
       #loop over all columns (parameters) for each port
       for c,j in enumerate(self.gdict[i]):
           inp_val = '{0:10}'.format(j)
           inp_max = '{0:10}'.format(self.gdict[i+'_max'][c])
           inp_min = '{0:10}'.format(self.gdict[i+'_min'][c])
   
           #create input text
           #self.ivar[i+'_'+self.plis[c]+'_min'].set(inp_min)
           self.ivar[i+'_'+self.plis[c]+'_med'].set(inp_val)
           #self.ivar[i+'_'+self.plis[c]+'_max'].set(inp_max)


    #Update parameters in gdict with percentage limit
    def set_limt_param(self,onenter):
        """
        This function will set the parameter limits after updating the range value in the lower right text box.

        Args
        ------
        self: class
            The GUI class in this module
        onenter: class
            Initiate on enter
   
        Returns
        --------
            None
        """
        #release cursor from entry box and back to the figure
        #needs to be done otherwise key strokes will not work
        self.f.canvas._tkcanvas.focus_set()

        #scale parameters value
        self.sc_limit = float(self.val_per.get().replace(' ',''))/100.

       # loop over string containing all the gdict keys (i.e. port names)
        for m,i in enumerate(self.b_keys):
            #loop over all parameters and update values (remove all white space before converting to float
            for c,j in enumerate(self.gdict[i]):
               #skip frozen parameters
               if self.p_code['{0:1d}'.format(c)] not in self.freeze_list: 
                   self.gdict[i+'_min'][c] = self.gdict[i][c]-np.abs(self.sc_limit*self.gdict[i][c])
                   self.gdict[i+'_max'][c] = self.gdict[i][c]+np.abs(self.sc_limit*self.gdict[i][c])


        #update parameters shown in the boxes
        self.iris_show()




    #Update parameters in gdict base on best fit values
    def get_iris_param(self,onenter):
        """
        This function will get the parameter limits from the parameter text boxes and update them in the fitting dictionary.

        Args
        ------
        self: class
            The GUI class in this module
        onenter: class
            Initiate on enter
   
        Returns
        --------
            None
        """
        #release cursor from entry box and back to the figure
        #needs to be done otherwise key strokes will not work
        self.f.canvas._tkcanvas.focus_set()

       # loop over string containing all the gdict keys (i.e. port names)
        for m,i in enumerate(self.b_keys):
            #loop over all parameters and update values (remove all white space before converting to float
            for c,j in enumerate(self.gdict[i]):
               self.gdict[i][c] = float(self.ivar[i+'_'+self.plis[c]+'_med'].get().replace(' ','')) 
               self.gdict[i+'_min'][c] = float(self.ivar[i+'_'+self.plis[c]+'_min'].get().replace(' ','')) 
               self.gdict[i+'_max'][c] = float(self.ivar[i+'_'+self.plis[c]+'_max'].get().replace(' ','')) 


    #Update shown parameters base on new best fit
    def iris_show(self):
        """
        This function will updated the parameter text boxes values based on the best fit.

        Args
        ------
        self: class
            The GUI class in this module
   
        Returns
        --------
            None
        """
       # loop over string containing all the gdict keys (i.e. port names)
        for m,i in enumerate(self.b_keys):
            #loop over all parameters and update values
            for c,j in enumerate(self.gdict[i]):
               self.ivar[i+'_'+self.plis[c]+'_min'].delete(0,'end')
               self.ivar[i+'_'+self.plis[c]+'_med'].delete(0,'end')
               self.ivar[i+'_'+self.plis[c]+'_max'].delete(0,'end')

               #set formatting based on output value
               if abs(self.gdict[i][c]) < .001:
                   dfmt = '{0:10.5e}'
               elif abs(self.gdict[i][c]) > 10000.:
                   dfmt = '{0:10.1f}'
               elif abs(self.gdict[i][c]) == 0:
                   dfmt = '{0:10d}'
               else:
                   dfmt = '{0:10.5f}'

               #update in text box
               #self.ivar[i+'_'+self.plis[c]+'_med'].insert(0,dfmt.format(self.gdict[i][c]))
               self.ivar[i+'_'+self.plis[c]+'_min'].insert(0,dfmt.format(self.gdict[i+'_min'][c]))
               self.ivar[i+'_'+self.plis[c]+'_med'].insert(0,dfmt.format(self.gdict[i][c]))
               self.ivar[i+'_'+self.plis[c]+'_max'].insert(0,dfmt.format(self.gdict[i+'_max'][c]))


         
    #set up data for plotting 
    def iris_dark_set(self):
        """
        This function reads in the IDL save files containing the dark trend information. It also sets default plotting symbols,
        linestyles, and colors per port.

        Args
        ------
        self: class
            The GUI class in this module
   
        Returns
        --------
            None
        """
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
        """
        This function will plot and IRIS pedestal data and the best fit parameters for each port.

        Args
        ------
        self: class
            The GUI class in this module
   
        Returns
        --------
            None
        """
        #clear the plot axes 
        for i in self.wplot.keys(): 

            #If a previous plot exists get x and y limits
            if self.lat_plot:
                #get previous x and y limits
                xlim = self.wplot[i].get_xlim()
                ylim = self.wplot[i].get_ylim()
  
            #clear previous plot
            self.wplot[i].clear()
            self.wplot[i].set_title(i.upper())
            self.wplot[i].set_xlabel('Offset Time [s]')
            self.wplot[i].set_ylabel('Pedestal Offset [ADU]')

            #If a previous plot exists set x and y limits
            if self.lat_plot:
                #set previous x and y limits
                self.wplot[i].set_xlim(xlim)
                self.wplot[i].set_ylim(ylim)

        #After first run through set lat(er)_plots to true
        self.lat_plot = True

        #best fit lines
        self.bline = {}
        #data scatter
        self.sdata = {}
       
        #plot data for all IRIS dark remaining pedestals
        for i in sorted(self.fdata.keys()):
            #Get plot associated with each port
            ax = self.wplot[i[:-1]] 
            #Put data in temp array
            dat = self.fdata[i]

            #set ptype attribute for curvefit and offset model 
            self.ptype = i[:-1]
            #set the current port variable
            self.cport= i 

            #get variance in best fit model
            var = self.get_var(i,self.gdict[i])
            #get offset in last data point
            last = self.get_last(i,self.gdict[i])

            #Uploaded best fit
            #current dark time plus a few hours
            ptim = np.linspace(self.fdata[i][0].min(),self.fdata[i][0].max()+1e3,500)
            #plot values currently in gdict for best fit values (store in dictionary for updating line)
            self.bline[i] = self.wplot[i[:-1]].plot(ptim,self.offset(ptim,*self.gdict[i]),color=self.fdata[i][3],label='{0}(Unc.) = {1:5.4f}'.format(i,var)) 

            #plot each port
            self.sdata[i] = ax.scatter(dat[0],dat[1],color=dat[3],marker=dat[4],label='{0}(last) = {1:3.2f}'.format(i,last))
            ax.errorbar(dat[0],dat[1],yerr=dat[2],color=dat[3],fmt=dat[4],label=None)
 

        #add legend
        for i in self.wplot.keys():
            self.wplot[i].legend(loc='upper left',frameon=True)
            #add fancy plotting
            fancy_plot(self.wplot[i])

        self.canvas.draw()


    #get variance in the model
    def get_var(self,port,parm):
        """
        This function will calculate the varience between the model and the data for a given port for the latest best fit model.

        Args
        ------
        self: class
            The GUI class in this module
        port: str
            String containing the port name (e.g. 'nuv1'), which is the dictionary key
        parm: np.array
            An array of parameter value to send to the offset function
   
        Returns
        --------
        var: float
            The sum squared error divided by N. That is the average uncertainty per observation.   
        """
        var = np.sqrt(np.sum((self.fdata[port][1]-self.offset(self.fdata[port][0],*parm))**2.)/float(len(self.fdata[port][0])))
        return var
    #get variance in the model
    def get_last(self,port,parm):
        """
        This function will calculate the varience between the model and the data for a given port using the previous model.

        Args
        ------
        self: class
            The GUI class in this module
        port: str
            String containing the port name (e.g. 'nuv1'), which is the dictionary key
        parm: np.array
            An array of parameter value to send to the offset function
   
        Returns
        --------
        var: float
            The sum squared error divided by N. That is the average uncertainty per observation.   
        """
        last = np.sqrt(((self.fdata[port][1]-self.offset(self.fdata[port][0],*parm))**2.))[-1]
        return last


    #Pedestal offset model
    def offset_old(self,dt0,amp1,amp2,p1,phi1,phi2,trend,quad,off,qscale):
        c = 2.*np.pi
        dtq = dt0-self.dtq0[self.ptype]
        #do not add quadratic term before start time
        dtq[dtq < 0.] = 0.

        #stop quad term after end time
        #range to adjust quadratic term over 2018/05/25 J. Prchlik
        adj, = np.where(dtq > self.dtq1[self.ptype]-self.dtq0[self.ptype])
        off = np.zeros(dtq.size)+off
        #adjust offset for given quad flattening time
        off[adj] = off[adj]+quad*(1-qscale)*(self.dtq1[self.ptype]-self.dtq0[self.ptype])**2+trend*(1-qscale)*(self.dtq1[self.ptype])
        dtq[adj] = (dtq[adj])*(qscale)**.5

        #adjust offset for given linear flattening time
        dtl = dt0.copy()
        dtl[adj] = (dtl[adj])*(qscale)

        #Default config
        return (amp1*np.sin(c*(dt0/p1+phi1)))+(amp2*np.sin(c*(dt0/(p1/2.)+phi2)))+(trend*(dtl))+(quad*(dtq**2.00))+(off)
        #trying to remove 6 month period because it is not the same thing (one is eclipse the other is orbital)
        #slightly better model 2017/12/06 which is more physically motivated uses sin^2
        #return (amp1*np.sin(c*(dt0/(p1)+phi1))**2.)+(amp2*np.sin(c*(dt0/(2.*p1)+phi2))**2.)+(trend*(dt0))+(quad*(dtq**2.))+(off)
        #Trying to at asymtopic function 
        #return (amp1*np.sin(c*(dt0/(p1)+phi1))**2.)+(amp2*np.sin(c*(dt0/(2.*p1)+phi2))**2.)+trend/(1.+np.exp(-quad*(dt0-1.4e8)))+off#(trend*(dt0))+(quad*(dtq**2.))+(off)
        #Trying a linear model with sin function
        #return ((amp1*np.sin(c*(dt0/(p1)+phi1))**2.)+(amp2*np.sin(c*(dt0/(2.*p1)+phi2))**2.))*((trend*(dt0))+(quad*(dtq**2.))+(off))
        #return (amp1*(np.sin(c*(dt0/(2.*p1)+phi1)))**2.)+(amp2*(np.sin(c*(dt0/(2.*p1/2.)+phi2))**2))+(trend*(dt0))+(quad*(dtq**2.))+(p2*(dt0**3.))+(off)

    ########################################################################################
    #!!!!!!Will need to update parameters in offset function as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters in offset function as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters in offset function as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters in offset function as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters in offset function as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters in offset function as you add new parameters!!!!!!
    ########################################################################################
    #Pedestal offset model
    def offset(self,dt0,amp1,amp2,p1,phi1,phi2,trend,quad,off,qscale,bo_drop,sc_amp,ns_incr):
        """
        This function creates the model used for fitting. If you want to add new parameters to the
        model, then you will need to add them this is function and document them. This function
        will get passed to the minimization routine when trying to derive new parameters.
        
        Args
        ------
        self: class
            The GUI class in this module
        dt0: np.array
            The time is referenced with seconds since t0dict reference, which is port dependent. There is one time for every dark observation.
        amp1: float
            The amplitude of the approximately 1 year sine function.
        amp2: float
            The amplitude of the approximately 1/2 year sine function.
        phi1: float
            The phase of the approximately 1 year sine function in radians.
        phi2: float
            The phase of the approximately 1/2 year sine function in radians.
        trend: float
            The linear coefficient explaining the increase in the pedestal level. 
        quad : float
            The quadratic coefficient explaining the increase in the pedestal level. 
        off:  float
            The intercept for the quadratic and linear function
        qscale: float
            The flattening of the linear and quadratic term after August 2017
        bo_drop: float
            The fractional drop in the offset (intercept term) due to the bake out on June 13-15, 2018
        sc_amp: float
            The amplication fraction in the in the sine function amplitudes due to the bake out on 
            June 13-15, 2018.
        ns_incr: float
            The fractional increase in the offset (intercept term) due to non-standard IRIS operations
            from October 27th to December 15th, 2018.
  
   
        Returns
        --------
        trend: float
            The value of the trend at each t0 for a given set of parameters.
        """



        #constant on period term
        c = 2.*np.pi
        dtq = dt0-self.dtq0[self.ptype]
        #do not add quadratic term before start time
        dtq[dtq < 0.] = 0.
        #Try removing quadratic term
        #2018/10/08 J. Prchlik
        #dtq = np.zeros(dtq.size)

        #stop quad term after end time
        #range to adjust quadratic term over 2018/05/25 J. Prchlik
        adj, = np.where(dtq > self.dtq1[self.ptype]-self.dtq0[self.ptype])
        off = np.zeros(dtq.size)+off
        #adjust offset for given quad flattening time
        off[adj] = off[adj]+quad*(1-qscale)*(self.dtq1[self.ptype]-self.dtq0[self.ptype])**2+trend*(1-qscale)*(self.dtq1[self.ptype])
        dtq[adj] = (dtq[adj])*(qscale)**.5

        #adjust offset for given linear flattening time
        dtl = dt0.copy()
        dtl[adj] = (dtl[adj])*(qscale)

        ################################################################################################################
        #Default config
        trend = (amp1*np.sin(c*(dt0/p1+phi1)))+(amp2*np.sin(c*(dt0/(p1/2.)+phi2)))+(trend*(dtl))+(quad*(dtq**2.00))+(off)
        ################################################################################################################

        ################################################################################################################
        #drop the trend following the June 2018 bakeout
        #Stop this trend once the non-standard coarse control of the telescope, which begins in Oct, 2018, end in Dec. 2018
        #post_bo = [((dt0 >  self.bojune152018-self.t0dict[self.cport]) & (dt0 < self.nsdec152018-self.t0dict[self.cport]))]
        #For now assumed the amplitude increase in the periodic trend presists after the bake and through the non-standard
        #operations in Oct.-Dec. 2018 J. Prchlik 2019/01/10
        post_bo = [((dt0 >  self.bojune152018-self.t0dict[self.cport]))]
        #Drop offset after June 2018 bake out by a fractional amount
        drop_trend_offset = -(bo_drop)*off
        #increase the amplitutude of the periodic terms after the June 2018 bake out by a fractional amount
        incs_trend_amplit = ((amp1*np.sin(c*(dt0/p1+phi1)))+(amp2*np.sin(c*(dt0/(p1/2.)+phi2))))*sc_amp

        #Trend after the 2018/06/15 bake out
        trend[post_bo] = (trend+drop_trend_offset+incs_trend_amplit)[post_bo]
        ################################################################################################################


        ################################################################################################################
        #Increase in the pedestal level following non-standard operations of the IRIS telescope from Oct.-Dec 2018
        post_ns = [(dt0 > self.nsdec152018-self.t0dict[self.cport])]
        #Increase pedestal offset after Oct.-Dec. 2018 non-standard operations by a fractional amount
        incr_trend_offset = (ns_incr)

        #Trend after the non-standard operations between Oct. 27th and Dec. 15 2018
        trend[post_ns] = (trend+incr_trend_offset)[post_ns]
 
        ################################################################################################################
        return trend

    #print data to terminal
    ##########################################################################
    #!!!!!!Will need to update parameters here as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters here as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters here as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters here as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters here as you add new parameters!!!!!!
    #!!!!!!Will need to update parameters here as you add new parameters!!!!!!
    ##########################################################################
    def Print(self):
        print('      {0:10},{1:10},{2:15},{3:10},{4:10},{5:20},{6:20},{7:10},{8:10},{9:10},{10:10},{11:10}'.format('Amp1','Amp2','P1','Phi1','Phi2','Trend','Quad','Offset','Scale','OffDrop','AmpInc','OffNSop'))
        for i in self.b_keys:
            print('{0}=[{1:^10.5f},{2:^10.5f},{3:^15.4e},{4:^10.5f},{5:^10.5f},{6:^20.9e},{7:^20.9e},{8:^10.5f},{9:10.5f},{10:10.5f},{11:10.5f},{12:10.5f}]'.format(i,*self.gdict[i]))


    #refit list (i.e. which ports should you refit)
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
            else:
                continue

    #parameter freeze list
    def freeze_list_com(self):
        #allows you to get back to the main part of the GUI
        self.f.canvas._tkcanvas.focus_set()

        #freeze limit percentage
        self.fr_limit = 0.0001

        #check which boxes are checked and use array locattion to update limits
        for m,i in enumerate(self.plis):
            #if checked and not in list update the list 
            if ((self.freeze_box[i+'_val'].get() == 1) and (i not in self.freeze_list)):
                self.freeze_list.append(i)
                #set selected limit to 0.0001* of primary value
                for j in self.b_keys:
                    self.gdict[j+'_min'][m] = self.gdict[j][m]-np.abs(self.fr_limit*self.gdict[j][m])
                    self.gdict[j+'_max'][m] = self.gdict[j][m]+np.abs(self.fr_limit*self.gdict[j][m])
            #if freezeed and already in the list continue 
            elif ((self.freeze_box[i+'_val'].get() == 1) and (i in self.freeze_list)):
                continue
            #if not freezeed remove from list and deselect
            elif ((self.freeze_box[i+'_val'].get() == 0) and (i in self.freeze_list)):
                self.freeze_list.remove(i)
                self.freeze_box[i].deselect()


                #set to global limit if sc_limit is set
                if isinstance(self.sc_limit,float):
                    for j in self.b_keys:
                        self.gdict[j+'_min'][m] = self.gdict[j][m]-np.abs(self.sc_limit*self.gdict[j][m])
                        self.gdict[j+'_max'][m] = self.gdict[j][m]+np.abs(self.sc_limit*self.gdict[j][m])
                else: 
                    #set unselected limit to infinity
                    for j in self.b_keys: self.gdict[j+'_min'][m],self.gdict[j+'_max'][m] = -np.inf,np.inf
            #if not freezeed and not in list do nothing
            else: continue

        self.iris_show() 


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

            #get the current port type
            self.ptype = i[:-1]
            #get current full port informtion (i.e. nuv1 or fuv2)
            self.cport = i
             

            #for j,k in enumerate(mins): print(k,guess[j],maxs[j])
            popt, pcov = curve_fit(self.offset,dt0,port,p0=guess,sigma=errs,bounds=(mins,maxs),xtol=1e-10) 


 
            #temporary line plot
            ptim = np.linspace(self.fdata[i][0].min(),self.fdata[i][0].max()+1e3,500)
            t_line, = self.wplot[i[:-1]].plot(ptim,self.offset(ptim,*popt),'--',color=self.fdata[i][3]) 
            self.canvas.draw()
           
            #get model variance 
            old_var = self.get_var(i,self.gdict[i])
            new_var = self.get_var(i,popt)

            #Ask if you should update the new parameter for a given fit
            if box.askyesno('Update','Should the Dark Trend Update for {0} (dashed line)?\n $\sigma$(old,new) = ({1:5.4f},{2:5.4f})'.format(i.upper(),old_var,new_var)):
                                      
                #update with new fit values
                self.gdict[i] = popt
                #update strings in GUI

            #remove temp line
            t_line.remove()
            self.canvas.draw()
        
        #update parameters in the box
        self.iris_show()
        #self.update_port_vals()
        #update plots
        self.iris_dark_plot()
            
    #resets parameter guesses
    def reset(self):
        self.gdict = self.idict.copy()
        self.iris_show()
        #self.update_port_vals()


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
    default_font = tkFont.nametofont("TkDefaultFont")
    default_font.configure(size=12)
    root.option_add("*Font", default_font)
    root.option_add("*Font", default_font)
    root.mainloop()


if __name__=="__main__":
#create root frame
   main()

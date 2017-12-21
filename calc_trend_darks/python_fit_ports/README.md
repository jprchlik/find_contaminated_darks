fit_ports_gui.py
================
A python GUI for fitting the long term pedestal trend of the IRIS CCDs. 
The program uses the sav file created by the main IDL program, 
so no additional file formatting required. 

The python GUI imports the following modules. I also included the version my code works with the modules
in case any future issues arise.

    a. matplotlib 2.0.0
    b. numpy 1.11.3
    c. Tkinter Revision: 81008
    d. scipy 1.0.0


To run the program type the following command in a terminal window:  
> python fit_ports_gui.py  


After typing the command you will be greeted with a GUI containing two plots.
The left and right plots contain the FUV and NUV, respectively, difference between the model pedestal and the measured dark
pedestal as a function of time. Both the FUV and NUV CCDs contain four ports for rapid read out of the CCD
 (port 1 = red circle, port 2 = blue square, port 3 = teal diamond, and port 4 = black triangle).
The plot also contains a model for the pedestal's evolution with the color corresponding to the port number. 
The model pedestal parameters' for CCD type and port are below their respective plots in the med row. Above and below 
the med row for each parameter is the maximum and minimum range to search for new parameters. The parameter range maybe 
set automatically by usieng the % Range text box in the bottom right of the gui.

When observed trend in a port consistently does not look like the model is the only reason to use the GUI.  
Fortunately, deviations from the trend do not happen to all ports at the same time.
Therefore, you are often only refitting a few port every three months,
which is why the GUI allow you to select the ports you want to refit.
Furthermore, the parameters not all parameters need refit every recalibration,
 which is why the GUI allows you to dynamic freeze some parameters. In the example below I only 
wanted to refit FUV port 3 for the Amplitude of the sin function. 
Selecting port and freezing parameters example below:   
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/v3VH7uBjTJw/0.jpg)](http://www.youtube.com/watch?v=v3VH7uBjTJw)

In the above example using an infinite range worked well. Frequently, using an unrestricted range causes the 
program to find nonoptimal minimums. Therefore, I included a range box in the lower right. The range box
sets the minimum and maximum allowed value for all thawed parameters. Of course this example did not benefit from
a restricted range, but it is an outlier not the norm.
Setting parameter range example below:  
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/1Nu14eoA0ww/0.jpg)](http://www.youtube.com/watch?v=1Nu14eoA0ww)

Finally, you will want to efficiently save new parameters. The GUI has the print button for that.
The print button print the new parameter values in a format for the iris_trend_fix program, as well as,
the initial_parameters.txt file.
Printing new parameters example below:  
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/jC0AbvZRth8/0.jpg)](http://www.youtube.com/watch?v=jC0AbvZRth8)


initial_parameters.txt
----------------------
A file containing a list of initial parameters for the long term pedestal offset model. 
The format is the same as the format printed by fit_ports_gui.py (e.g. below).


\     Amp1      ,Amp2      ,P1             ,Phi1      ,Phi2      ,Trend               ,Quad                ,Offset    
fuv1=[ 0.16210  , 0.02622  ,  3.1504e+07   , 0.41599  , 0.09384  ,  2.819499502e-08   ,  5.705285157e-16   , -0.56933 ]  
fuv2=[ 0.25704  , 0.19422  ,  3.1568e+07   , 0.37571  , 0.89102  ,  2.832588907e-08   ,  4.108370809e-16   , -0.54180 ]  
fuv3=[ 1.46520  , 1.62863  ,  3.1522e+07   , 0.33362  , 0.87265  ,  2.618708232e-08   ,  1.219050166e-15   , -0.60404 ]  
fuv4=[ 0.27947  , 0.14585  ,  3.1383e+07   , 0.39938  , 0.90869  ,  1.880687110e-08   ,  9.619889318e-16   , -0.59357 ]  
nuv1=[ 0.55495  , 0.53251  ,  3.1782e+07   , 0.32965  , -0.07967 ,  3.995823558e-09   ,  2.297179460e-16   , -0.16966 ]  
nuv2=[ 0.73259  , 0.68243  ,  3.1841e+07   , 0.33437  , 0.92937  ,  3.278569052e-09   ,  2.743724242e-16   , -0.21646 ]  
nuv3=[ 0.26427  , 0.24439  ,  3.1696e+07   , 0.33597  , 0.91779  ,  1.004922804e-08   ,  3.098606381e-16   , -0.12297 ]  
nuv4=[ 0.41707  , 0.44189  ,  3.1642e+07   , 0.32680  , 0.90548  ,  7.943234757e-09   ,  3.284834996e-16   , -0.21366 ]  
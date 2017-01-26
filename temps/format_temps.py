from astropy.io import ascii


def format_file(infil):


    oufile = infil.replace('.txt','.fmt')
    dat = ascii.read(infil)


#    dat = dat['DATE_OBS','ITF1CCD1','ITF2CCD2','ITNUCCD3','ITSJCCD4','BT06CBPX','BT07CBNX']
#Added more temperatures which show an overall positive trend
    cols = ['DATE_OBS','ITF1CCD1','ITF2CCD2','ITNUCCD3','ITSJCCD4','BT06CBPX','BT07CBNX','BT10HOPA','BT17SMAP','IT01PMRF','IT03PMRA','IT04TELF','IT12HOPA','IT13FRAP']
    dat = dat[cols]


    hmt = '{0:^25} '
    fmt = '{0:^25} ' 
    for i in range(1,len(cols)):
#        fmt = fmt+' {'+str(i)+':^10.2f}'
        fmt = fmt+' {'+str(i)+':^10}'
        hmt = hmt+' {'+str(i)+':^10}'

    #add new line at end of line
    fmt = fmt+'\n'
    hmt = hmt+'\n'


    out = open(oufile,'w')
#write header
    out.write(hmt.format('DATE_OBS','ITF1CCD1','ITF2CCD2','ITNUCCD3','ITSJCCD4','BT06CBPX','BT07CBNX','BT10HOPA','BT17SMAP','IT01PMRF','IT03PMRA','IT04TELF','IT12HOPA','IT13FRAP'))
    for i in dat:
        out.write(fmt.format(i['DATE_OBS'],i['ITF1CCD1'],i['ITF2CCD2'],i['ITNUCCD3'],i['ITSJCCD4'],i['BT06CBPX'],i['BT07CBNX'],i['BT10HOPA'],i['BT17SMAP'],i['IT01PMRF'],i['IT03PMRA'],i['IT04TELF'],i['IT12HOPA'],i['IT13FRAP']))
     

    out.close()




    return
    


#files =  glob.glob('*temp.txt')
#
#nproc= 10
#
##format_file(files[0])
#pool = Pool(processes=nproc)
#output = pool.map(format_file,files)
#pool.close()
#
#
#
#

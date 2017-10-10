####init api to parse Google calendar for calibration-as-run for Calib3: darks
from __future__ import print_function
import httplib2
import os,sys
from errno import errorcode

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

import datetime
#get string to send to sswidl for dark files
import get_dark_files as gdf

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/calendar-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/calendar.readonly'
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'Google Calendar API Python Quickstart'
def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    home_dir = os.path.expanduser('~')
    credential_dir = os.path.join(home_dir, '.credentials')
    if not os.path.exists(credential_dir):
        os.makedirs(credential_dir)
    credential_path = os.path.join(credential_dir,
                                   'calendar-python-quickstart.json')

    store = Storage(credential_path)
    credentials = store.get()
    if not credentials or credentials.invalid:
        flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
        flow.user_agent = APPLICATION_NAME
        if flags:
            credentials = tools.run_flow(flow, store, flags)
        else: # Needed only for compatibility with Python 2.6
            credentials = tools.run(flow, store)
        #print('Storing credentials to ' + credential_path)
    return credentials

def main():
    """Shows basic usage of the Google Calendar API.

    Creates a Google Calendar API service object and outputs a list of the 
    Dark runs on IRIS calibration-as-run calendar.
    """
    credentials = get_credentials()
    http = credentials.authorize(httplib2.Http())
    service = discovery.build('calendar', 'v3', http=http)
#    calendar_list_entry = service.calendarList().get(calendarId='calendarId').execute()
#    print(calendar_list_entry['summary'])
    
#GET LIST OF CALENDARS 
#    page_token = None
#    while True:
#      calendar_list = service.calendarList().list(pageToken=page_token).execute()
#      for calendar_list_entry in calendar_list['items']:
#        print(calendar_list_entry)
#      page_token = calendar_list.get('nextPageToken')
#      if not page_token:
#        break

    span = 15
    now = datetime.datetime.utcnow().isoformat() + 'Z' # 'Z' indicates UTC time
    onmonth = (datetime.datetime.utcnow()-datetime.timedelta(days=span)).isoformat()+'Z'
#    print('Getting days with darks')
    eventsResult = service.events().list(
        calendarId='27f4lqaadrbrp1nueps13qq2n0@group.calendar.google.com', timeMin=onmonth,timeMax=now, singleEvents=True, #IRIS calibration-as-run
        orderBy='startTime').execute()
    events = eventsResult.get('items', [])


    darks = 'Calib 3: Dark'.upper().replace(' ','').replace(':','')


#variable to check whether all req. passed
    outc = 0 #zero means all is good

#    if not events:
#        print('No darks found in last {0:3d}.'.format(span))
#Check that you don't reprocesss/redownload recently processed darks
    darkf = "processed_dark_months"
    prev = open(darkf,"r")
    check = prev.readlines()
#set up so you only get the last event
    found = False
    for event in events:
        start = event['start'].get('dateTime', event['start'].get('date'))
        eventstring = event['summary'].upper().replace(' ','').replace(':','')
        if ((eventstring == darks) | (eventstring == darks+'S')):
            out = start.split('-')
# do the check to make sure the files are not already processed
            checkd = out[0]+'/'+out[1]+'/'+out[2]+"\n"
            if checkd  in check: 
                sys.stdout.write('FAILED, ALREADY PROCESSED THIS MONTHS DARKS')
                outc = 1
                return outc
#                sys.exit(1)

#get and download simpleb darks
            darkd = gdf.dark_times(out[0]+'/'+out[1]+'/'+out[2],simpleb=True)
            darkd.run_all()
#ERROR NICELY if download fails
#            try:
#                darkd.run_all() # download darks from jsoc
#            except:
#                outc = 1
#                return outc
#
#get and download complexa darks
            darkd = gdf.dark_times(out[0]+'/'+out[1]+'/'+out[2],complexa=True)
            darkd.run_all()
#ERROR NICELY if download fails
#            try:
#                darkd.run_all() # download darks from jsoc
#            except:
#                outc = 1
#                return outc
#

            out = out[1]+','+out[0]
            found = True
#print MM/YYYY and add YYYY/MM/DD to dark file
    if ((found) & (outc == 0)): 
        sys.stdout.write(out)
        check.append(checkd)
        prev = open(darkf,'w')
        for k in check: prev.write(k)
        prev.close()
        outc = 0
 
    else: 
        sys.stdout.write('FAILED, NO DARKS FOUND')
        outc = 1
#        sys.exit(1)

    return outc #return output code
     


if __name__ == '__main__':
    try:
        outc = main()
    except:
        outc = 2
    if outc > 1:
        sys.stdout.write("FAILED, UNKNOWN REASON (PROBABLY CODING)")

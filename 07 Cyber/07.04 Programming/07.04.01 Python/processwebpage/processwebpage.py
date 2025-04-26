import re
import requests
from datetime import datetime

response = requests.get("https://vic.gov.au/sites/default/files/2021-09/Victorian-public-holiday-dates.ics")
#print(response.text)

matches=re.findall(r'(BEGIN:VEVENT.*?DTSTART;VALUE=DATE:(\d*).*?DTEND;VALUE=DATE:(\d*).*?SUMMARY:(.*?)\r.*?END:VEVENT)',response.text,re.DOTALL)

holidays = {}

for holiday in matches:
    dateStart = datetime.strptime(holiday[1], '%Y%m%d').date()

    holidays[holiday[3]] = dateStart

for aHoliday in holidays:
    theHoliday = aHoliday
    theDate = holidays[theHoliday]
    print(aHoliday + " occurs on " + theDate.strftime('%A %d %B, %Y'))

#print(holidays)
#    if holiday[3] == "Good Friday":
#        print("The holiday: "+holiday[3]+", starts on "+holiday[1]+" and ends on "+holiday[2])

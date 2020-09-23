# aqi

mac status bar app to show AQI from purpleair api

It'll refresh the value every 5 minutes. Click the value to open the map.

disclaimer: I have no idea what I'm doing with swift, or air science

Based on the purple air api, see https://docs.google.com/document/d/15ijz94dXJ-YAZLi9iZ_RaBwrZ4KtYeCy08goGBwnbCU/edit

## customizing

Find the ID of the monitoring station you want by poking around the network tab of your browser dev tools on the purple air map, eg `https://www.purpleair.com/map?opt=1/mAQI/a10/cC0#9.73/45.5249/-122.6215`

The station ID should be on a request like `https://www.purpleair.com/json?show=43023`, where 43023 is the ID in this example.

Update the SENSOR_ID constant in the AppDelegate.swift file and rebuild. (I told you I have no idea what I'm doing with swift)

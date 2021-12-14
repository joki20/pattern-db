"""
You should only need to update the constants (capitalized variable names)
to get the data you want.
Formula based on MATLAB code from https://web.archive.org/web/20161209044600/http://williams.best.vwh.net/avform.htm#LL
(relevant excerpt below).
A point {lat,lon} is a distance d out on the tc radial from point 1 if:
     lat=asin(sin(lat1)*cos(d)+cos(lat1)*sin(d)*cos(tc))
     IF (cos(lat)=0)
        lon=lon1      // endpoint a pole
     ELSE
        lon=mod(lon1-asin(sin(tc)*sin(d)/cos(lat))+pi,2*pi)-pi
     ENDIF
This algorithm is limited to distances such that dlon <pi/2, i.e those that extend around less than one quarter of the circumference of the earth in longitude. A completely general, but more complicated algorithm is necessary if greater distances are allowed:
     lat =asin(sin(lat1)*cos(d)+cos(lat1)*sin(d)*cos(tc))
     dlon=atan2(sin(tc)*sin(d)*cos(lat1),cos(d)-sin(lat1)*sin(lat))
     lon=mod( lon1-dlon +pi,2*pi )-pi
"""
from math import sin, cos, asin, pi
import random
# requires pandas to be installed, eg `python3 -m pip install pandas`
import pandas as pd

# -- CONSTANTS --
# https://en.wikipedia.org/wiki/Earth_radius
EARTH_RADIUS_KM = 6371
# Skövde center according to Google Maps
CENTER_P = {"lat": 59.8332051, "lon": 17.5183649}
MAX_DISTANCE_KM = 10
OUTPUT_FILE_NAME = 'uppsala_latlon.csv'
# -- END CONSTANTS --

def random_point(max_dist_km, center_lat, center_lon):
    distance_centre_km = random.random() * max_dist_km
    # distance in radians
    d = distance_centre_km/EARTH_RADIUS_KM
    # 'radial' degrees in radians
    tc = random.random() * 2 * pi
    c_lat_rad = center_lat / 180 * pi
    c_lon_rad = center_lon / 180 * pi

    lat_radians = asin(sin(c_lat_rad)*cos(d)+cos(c_lat_rad)*sin(d)*cos(tc))
    lon_radians = ( (c_lon_rad-asin(sin(tc)*sin(d)/cos(lat_radians))+pi) % (2*pi)) - pi
    lat_deg = lat_radians / pi * 180
    lon_deg = lon_radians / pi * 180
    return lat_deg, lon_deg

# use function to generate points
rand_points = [random_point(5, CENTER_P['lat'], CENTER_P['lon']) for x in range(334)]
lats = [p[0] for p in rand_points]
lons = [p[1] for p in rand_points]

# bundle data in pandas dataframe and export to CSV file
latlon_df = pd.DataFrame({"lat": lats, "lon": lons})
latlon_df.to_csv(OUTPUT_FILE_NAME, index=False)

"""
Bonus code for testing if point generation works as expected,
using Plotly package (`pip install plotly`) to generate a
map plot.
import plotly.express as px
fig = px.scatter_geo(latlon_df, lat="lat", lon="lon", center=CENTER_P)
fig.update_geos(fitbounds="locations")
fig.show()
"""

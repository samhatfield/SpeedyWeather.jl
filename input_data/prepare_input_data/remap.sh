#!/bin/bash

# Script for preparing input data for SpeedyWeather.jl.
# NOTE: For now this script only works for orography.
#
# Origin of input data:
# - orography: the 1.25 km orography grid of the IFS. This was interpolated
#   down to 9 km to give orog_TCO1279.nc.
#
# Requires: cdo

supported_res=("T31" "T42" "T85" "T170" "T341" "T682")

# Process arguments
if [ $# -lt 1 ]; then
    echo "remap.sh resolution"
    echo "Supported resolutions:"
    echo ${supported_res[@]}
    exit 1
fi

res="$1"

# Check resolution is supported
if [[ ! " ${supported_res[@]} " =~ " $res " ]]; then
    echo "Resolution $res not supported"
    echo "Supported resolutions:"
    echo ${supported_res[@]}
    exit 1
fi

# Set the number of latitudes and longitudes
case $res in
    T31)
        nlon=96; nlat=48;;
    T42)
        nlon=128; nlat=64;;
    T85)
        nlon=256; nlat=128;;
    T170)
        nlon=512; nlat=256;;
    T341)
        nlon=1024; nlat=512;;
    T682)
        nlon=2048; nlat=1024;;
esac

echo "Remapping TCO1279 orography to ${res} (${nlon} x ${nlat})"
echo "NOTE: Negative values resulting from the remapping are set to zero"
# For some reason the remapbil operator flips the latitudes, so we invert them
# back here
cdo abs -invertlat -remapbil,r${nlon}x${nlat} orog_TCO1279.nc orog_${res}.nc


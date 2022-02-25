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
        nlat=48;;
    T42)
        nlat=64;;
    T85)
        nlat=128;;
    T170)
        nlat=256;;
    T341)
        nlat=512;;
    T682)
        nlat=1024;;
esac

echo "Remapping TCO1279 orography to ${res} ($((nlat*2)) × ${nlat})"
echo "NOTE: Negative values resulting from the remapping are set to zero"
cdo abs -remapbil,n$((nlat/2)) orog_TCO1279.nc orog_${res}.nc


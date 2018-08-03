#!/bin/bash
#SBATCH --job-name=nearest_hotspot_analysis
#SBATCH --time=24:00:00
#SBATCH --partition=broadwl
#SBATCH --cpus-per-task=4
#SBATCH --exclusive
#SBATCH --output=nearest_hs.out
stata-mp master.do

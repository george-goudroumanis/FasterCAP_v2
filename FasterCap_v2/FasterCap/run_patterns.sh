#!/bin/bash

# Iterate through each file in the source folder
for file in ../../../0605.patterns/FasterCap_3D_Patterns/*
do
  metallayer=$(basename $file)
  for Metal in $file/*
  do
    patterntype=$(basename $Metal)
    if [ $patterntype == 'Over' ]
    then

      for pattern in $Metal/*
      do
        patternname=$(basename $pattern)
        mkdir -p ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype
        
        if [[ $patternname == *"W0.21"* ]]; then
          if [[ $patternname == *"S0.14"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
           if [[ $patternname == *"S0.21"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.28"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.35"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.42"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          fi
        fi
      done
    fi
  done
done

# Iterate through each file in the source folder
for file in ../../../0605.patterns/FasterCap_3D_Patterns/*
do
  metallayer=$(basename $file)
  for Metal in $file/*
  do
    patterntype=$(basename $Metal)
    if [ $patterntype == 'Under' ]
    then

      for pattern in $Metal/*
      do
        patternname=$(basename $pattern)
        mkdir -p ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype

        if [[ $patternname == *"W0.21"* ]]; then
          if [[ $patternname == *"S0.14"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.21"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.28"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.35"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.42"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          fi
        fi
      done
    fi
  done
done

# Iterate through each file in the source folder
for file in ../../../0605.patterns/FasterCap_3D_Patterns/*
do
  metallayer=$(basename $file)
  for Metal in $file/*
  do
    patterntype=$(basename $Metal)
    if [ $patterntype == 'DiagUnder' ]
    then

      for pattern in $Metal/*
      do
        patternname=$(basename $pattern)
        mkdir -p ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype

        if [[ $patternname == *"W0.21"* ]]; then
          if [[ $patternname == *"S0.14"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.21"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.28"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.35"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          elif [[ $patternname == *"S0.42"* ]]; then
            echo $pattern
            ./FasterCap -b $pattern -g -ap -a0.1 > ../../../0605.patterns/FasterCap_3D_Patterns_Results/$metallayer/$patterntype/$patternname\_a_0.1_th_8.log
          fi
        fi
      done
    fi
  done
done

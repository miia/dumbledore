#!/bin/sh
RESULTFILE="pareto.m"
VERBOSE=0
if [ "$#" -eq 1 ] 
then
  if [ "$1" = "-v"  ] 
  then
    VERBOSE=1
  fi
fi
 
echo "[" > $RESULTFILE

reportdir=reports
for file in `ls $reportdir/DLX_*ns_*mW_timing.rpt`
do
  powfile=`echo $file | sed -e "s/$reportdir\/\(DLX_.*ns.*W\)_timing/$reportdir\/\1_power/g"`
  areafile=`echo $file | sed -e "s/$reportdir\/\(DLX_.*ns.*W\)_timing/$reportdir\/\1_area/g"`
  ns=`echo $file | sed -e "s/$reportdir\\/DLX_\(.*\)ns_.*mW.*/\\1/g"`
  uW=`echo $file | sed -e "s/$reportdir\\/DLX_.*ns_\(.*\)mW.*/\\1/g"`
  if [ $VERBOSE -eq 1 ]
  then
    echo "Analyzing report for $ns ns - $uW mW..."
  fi

  #Analyze the files

  #Using data arrival time doesn't keep into account everything dc_shell does, sum period+slack instead
  #time=`sed -n -e "/^.*data arrival time.*$/p" $file | sed -e "s/^.*data arrival time[[:blank:]]*\([0-9.]*\)[[:blank:]]*$/\1/g" | head -n 1`
  slack=`sed -n -e "/^[[:blank:]]*slack.*$/p" $file | sed -e "s/^[[:blank:]]*slack[[:blank:]]*(MET)[[:blank:]]*\([0-9.]*\)[[:blank:]]*$/\1/g" | head -n 1`
  time=`echo "scale=5; $ns - $slack" | bc `
  dynpower=`sed -n -e "/^Total Dynamic Power.*$/p" $powfile | sed -e "s/^[[:blank:]]*Total Dynamic Power[[:blank:]]*=[[:blank:]]*\([0-9.]*\)[[:blank:]]*mW[[:blank:]]*([0-9]*%)[[:blank:]]*$/\1/" | head -n 1`
  leakpower=`sed -n -e "/^Cell Leakage Power.*$/p" $powfile | sed -e "s/^[[:blank:]]*Cell Leakage Power[[:blank:]]*=[[:blank:]]*\([0-9.]*\)[[:blank:]]*mW[[:blank:]]*[[:blank:]]*$/\1/" | head -n 1`
  totalpower=`echo "scale=5; $dynpower+$leakpower"|bc`
  area=`sed -n -e "/^Total cell area.*$/p" $areafile | sed -e "s/^[[:blank:]]*Total cell area:[[:blank:]]*\([0-9.]*\)[[:blank:]]*$/\1/" | head -n 1`

#Saves results
  echo "$time $totalpower $area;" >> $RESULTFILE

  if [ $VERBOSE -eq 1 ]
  then
    echo -e "\tArrival time: $time"
    echo -e "\tTotal power: $totalpower"
    echo -e "\tTotal area: $area"
  fi

done

echo "]" >> $RESULTFILE

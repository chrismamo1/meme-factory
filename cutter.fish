#!/usr/bin/fish
#line 1 "/home/chrismamo1/programming/meme-factory/src/cutter.fish"
#line 1 "math.fish"


function abs
  set X $argv[1]
  if math "$X < 0" > /dev/null
    echo (math "0 - $X")
  else
    echo $X
  end;
end;

function scalc
  echo (calc -p $argv[1] | sed -n -e 's/\~\{0,1\}\(.*\)$/\1/p')
end
#line 2 "/home/chrismamo1/programming/meme-factory/src/cutter.fish"
#line 1 "time.fish"
#line 3 "time.fish"
#line 1 "math.fish"
#line 4 "time.fish"
function parse_time
  set HOURS (echo $argv[1] | sed -n -e 's/^\([-0-9]\+\):\([-0-9]\+\):\([-0-9]\+\.[0-9]\+\)/\1/p')
  set MINUTES (echo $argv[1] | sed -n -e 's/^\([-0-9]\+\):\([-0-9]\+\):\([-0-9]\+\.[0-9]\+\)/\2/p')
  set SECONDS (echo $argv[1] | sed -n -e 's/^\([-0-9]\+\):\([-0-9]\+\):\([-0-9]\+\.[0-9]\+\)/\3/p')
  echo $HOURS
  echo $MINUTES
  echo $SECONDS
end;

function format_time
  printf "%02d:%02d:%.5f" $argv[1] $argv[2] $argv[3]
end;

function abs_time
  set T (parse_time $argv[1])

  set HOURS $T[1]
  set MINUTES $T[2]
  set SECONDS $T[3]

  echo (format_time (abs $HOURS) (abs $MINUTES) (abs $SECONDS))
end;

function negate_time
  set T (parse_time $argv[1])
  echo (format_time (math "0 - $T[1]") (math "0 - $T[2]") (math "0 - $T[3]"))
end;

function sum_times
  set PFIRST (parse_time $argv[1])
  set PSECOND (parse_time $argv[2])
  set SECONDS (math "$PFIRST[3] + $PSECOND[3]")
  set MINUTES 0
  if math "$SECONDS>60.0" > /dev/null
    set MINUTES 1
    set SECONDS (math "$SECONDS - 60")
  end;
  set MINUTES (math "$MINUTES + $PFIRST[2] + $PSECOND[2]")
  set HOURS 0
  if math "$MINUTES>60" > /dev/null
    set HOURS 1
    set MINUTES (math "$MINUTES - 60")
  end;
  set HOURS (math "$HOURS + $PFIRST[1] + $PSECOND[1]")
  echo (format_time $HOURS $MINUTES $SECONDS)
end;

function get_seconds_from_time
  set TIME (parse_time $argv[1])
  set SECS (printf "%f" $TIME[3])

  echo (calc -p "(($TIME[1]) * 60 * 60) + (($TIME[2]) * 60) + ($SECS)" | sed -n -e 's/\~\{0,1\}\(.*\)$/\1/p')
end;

function get_time_from_seconds
  set S $argv[1]
  set TIME (calc -p "floor($S / 3600)" | sed -n -e 's/\~\{0,1\}\(.*\)/\1/p')
  set TIME $TIME (calc -p "floor($S / 60) % 60" | sed -n -e 's/\~\{0,1\}\(.*\)/\1/p')
  set TIME $TIME (calc -p "$S % 60" | sed -n -e 's/\~\{0,1\}\(.*\)/\1/p')
  echo (format_time $TIME)
end;

function diff_times
  set A (get_seconds_from_time $argv[1])
  set B (get_seconds_from_time $argv[2])

  echo (get_time_from_seconds (calc "abs($A - $B)" | sed -n -e 's/\~\{0,1\}\(.*\)/\1/p'))
end;
#line 3 "/home/chrismamo1/programming/meme-factory/src/cutter.fish"

function cut
  set VIDEO $argv[1]
  set AT $argv[2]
  set TO $argv[3]
  set FIRST "1_$VIDEO"
  ~/bin/ffmpeg -i $VIDEO -strict -2 -vcodec copy -acodec copy -ss $AT -to $TO $FIRST > /dev/null ^ /dev/null
  echo $FIRST
end;

function split
  set VIDEO $argv[1]
  set OUTVIDEO "video_$VIDEO.out"
  set OUTAUDIO "audio_$VIDEO.out"
  ~/bin/ffmpeg -i $VIDEO -map 0:0 -vcodec copy $OUTVIDEO -map 0:1 -acodec copy $OUTAUDIO > /dev/null ^ /dev/null
  echo $OUTVIDEO
  echo $OUTAUDIO
end;

function warp
  function get_vfilter
    set X $argv[1]
    if math "$X<0.5" > /dev/null
      set XP (scalc "$X / 0.5")
      set NEXT ""
      if math "$XP<0.5" > /dev/null
        set NEXT (get_vfilter $XP)
        set NEXT ",$NEXT"
      else
        set NEXT ",setpts=$XP*PTS"
      end
      set RV "setpts=0.5*PTS$NEXT"
      echo $RV
    else
      echo "setpts=$X*PTS"
    end
  end
  function get_afilter
    set X $argv[1]
    if math "$X>2.0" > /dev/null
      set XP (scalc "$X / 2.0")
      set NEXT ""
      if math "$XP>=2.0" > /dev/null
        set NEXT (get_afilter $XP)
        set NEXT ",$NEXT"
      else
        set NEXT ",atempo=$XP"
      end
      set RV "atempo=2.0$NEXT"
      echo $RV
    else
      echo "atempo=$X"
    end
  end
  set WFACTOR $argv[1]
  set PTS_SCALE (calc -p "1.0 / $argv[1]" | sed -n -e 's/\~\{0,1\}\(.*\)/\1/p')
  set INVIDEO $argv[2]
  set OUTVIDEO "out_$INVIDEO"

  set VFILTER (get_vfilter $PTS_SCALE)
  set AFILTER (get_afilter $WFACTOR)

  echo VFILTER $VFILTER >> filters.txt
  echo AFILTER $AFILTER >> filters.txt

  set TMP (~/bin/ffmpeg -i $INVIDEO -strict -2 -c:v h264 -preset veryfast -crf 10 -b:a 180k -vf "[in]$VFILTER:[out]" -af "[in]$AFILTER:[out]" -quality good $OUTVIDEO > /dev/null ^ /dev/null) > /dev/null ^ /dev/null
  rm $INVIDEO
  mv $OUTVIDEO $INVIDEO
end;

function staircase_warp
  echo Running staircase warp on $argv
  set FACTORS "1.05"
  set I 1
  echo Setting factors
  for I in (seq (count $argv))
    echo I $I
    set VID $argv[$I]
    echo Setting factor $I to (scalc "1.05 ** ($I + 1)")
    set FACTORS $FACTORS (scalc "1.05 ** $I")
  end;

  echo Warping videos
  set I 1
  for I in (seq (count $argv))
    set VIDP $argv[$I]
    echo Warping video $VIDP by a factor of $FACTORS[$I]
    warp $FACTORS[$I] $argv[$I]
    set I (scalc "$I+1")
  end;
end;

set VIDEOFILE $argv[1]
set TIMESFILE $argv[2]

set TIMES (cat $TIMESFILE)
echo Times are $TIMES

set POS '00:00:00.00'

set PREV "$VIDEOFILE"
set CLEANUP $PREV
set I 0

set START 0.0

for X in $TIMES
  echo "Extracting video segment from $START to $X..."
  set RES (cut $VIDEOFILE $START $X)
  set START $X
  set FNAME "$I-$VIDEOFILE"
  mv $RES $FNAME

  set SLICES $SLICES "$I-$VIDEOFILE"
  set PREV $FNAME
  set I (math "$I+1")
  set CLEANUP $CLEANUP $RES
  echo Result $FNAME
end;

set TL $SLICES[2..(count $SLICES)]

echo TL $TL

staircase_warp $TL

touch segments.txt
rm segments.txt
touch segments.txt
for x in $SLICES
  echo "file '$x'" >> segments.txt
end;

echo Concatenating files, this should not take long

~/bin/ffmpeg -f concat -safe 0 -i segments.txt -c copy "output-$VIDEOFILE" > /dev/null ^ /dev/null

echo Slices $SLICES
echo Cleanup $CLEANUP

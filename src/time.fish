#ifndef TIME_FISH
#define TIME_FISH
#include "math.fish"
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
#endif

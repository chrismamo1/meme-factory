#ifndef MATH_FISH
#define MATH_FISH
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
#endif

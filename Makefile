cutter.fish: src/cutter.fish src/time.fish src/math.fish
	echo '#!/usr/bin/fish' > cutter.fish
	mcpp src/cutter.fish >> cutter.fish
	chmod u+x cutter.fish

all: cutter.fish

clean:
	rm cutter.fish

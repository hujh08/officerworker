dir_bin=/AstroTools/Toolbox/bin

# bash script
scripts_sh = officer worker

# all scripts
scripts = $(scripts_sh)

all:
	echo 'ready to make install'
install : $(scripts)

$(scripts) : % : %.sh
	cp $^ $(dir_bin)/$@
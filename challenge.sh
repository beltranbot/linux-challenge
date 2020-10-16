#!/bin/bash

dictionary="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
divisor=${#dictionary}
line_length=15
max_size_allowed=1000000
TEMP_FILE=$(mktemp ./randomlines.XXXXXXXX)
SORTED_TEMP_FILE="$TEMP_FILE.sorted"

generate_random_line() {
	# using a dictionary we can generate a random number and then divide it
	# by the length or the dictionary, using the remainder we can randomly select
	# characters from the dictionary until we form a full line.

	line=""
	for (( i=0; i<=$line_length; i++)) 
	do
		position=$(( $RANDOM % $divisor ))
		random_char=${dictionary:position:1}
		line="$line$random_char"
	done
	echo $line
}

get_filesize_stat() {
	echo $(stat -c %s $TEMP_FILE)
}

get_filesize_disk_usage() {
	echo $(du -b $TEMP_FILE | cut -f 1)
}

generate_file() {
	# the temporal file was created at the start of the script
        # in every iteration we check whether the current size of 
	# the file surpases an arbitrary allowed max size
	# once the size limit is surpassed the loop stops

	while [[ $(get_filesize_stat) -le $max_size_allowed ]]
	do                
		line=$(generate_random_line)
		echo $line >> $TEMP_FILE
	done
}

generate_file_faster() {
	# translates random bytes from /dev/urandom into the acceptable characters 'a-zA-Z0-9'
	# and then fold them in the desire line_length
	# head controls that the file size doesn't goes over the desired value
	# references: https://stackoverflow.com/a/47501991/6594770, https://ostechnix.com/create-files-certain-size-linux/ 

	$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $line_length | head -c $max_size_allowed > $TEMP_FILE)
}

sort_file() {
	# sort without any option echoes the sorted content of the file: sort <filename>
	# the -o option allows to redirect output to a file
	# the order in which the strings are sorted seem to be: numerical values [0-9] -> alphabetic values [a-zA-Z]
	# it seems that in some cases lower and upper cases of letters have the same "sorting order",
	# this means that the sort command will place different cases of a letter interchangebly in the output.
	# this behavior can be changed by overwritting localization variables of the output as follow
	# for example: LC_ALL=C sort <filename>
	# this will force the ASCII's sorting order on the sort function giving the following output ordering:
        # numerical value [0-9] -> upper case alphabetic values [A-Z] -> lower case alphabetic values [a-z]
	# reference: https://unix.stackexchange.com/a/87763 

	$(sort $TEMP_FILE -o $TEMP_FILE)
}

remove_lines_starting_with_a() {
	# using sed the lines that start with the letter a can removed.
	# the I option can be used to ignore-case: sed '/^a/Id' <filename> > <output_file>
	# or specify both cases within a group in the regular expression: sed '/^[aA]/d' <filename> > <output_file>
	
	$(sed '/^[aA]/d' $TEMP_FILE > $SORTED_TEMP_FILE)
}

count_and_print_removed_lines() {
	original_number_of_lines=$(wc -l $TEMP_FILE | cut -d " " -f 1)
	number_of_lines_after_removal=$(wc -l $SORTED_TEMP_FILE | cut -d " " -f 1)
	echo "Number of lines removed: $(( $original_number_of_lines - $number_of_lines_after_removal ))"
}

if [[ "$1" == "faster" ]] ; then
	generate_file_faster
else
	generate_file
fi

sort_file
remove_lines_starting_with_a
count_and_print_removed_lines

exit 0

 


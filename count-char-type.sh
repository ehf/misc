#!/usr/bin/env bash

## example:
##  $ bash count-char-type.sh $pw_to_check
##  Uppercase           3
##  Lowercase          24
##  Number              4
##  Special             1
##


# char types to check
has_uppercase() { [[ $1 =~ [[:upper:]] ]]; }
has_lowercase() { [[ $1 =~ [[:lower:]] ]]; }
has_number() { [[ $1 =~ [[:digit:]] ]]; }
has_special() { [[ $1 =~ [[:punct:]] ]]; }


uppercase_count=0
lowercase_count=0
number_count=0
special_count=0
string_to_check=( $(echo "$1" | grep -o .) )
for char in "${string_to_check[@]}"; do
    #echo ${string_to_check[@]}
	if has_uppercase "$char"; then ((uppercase_count++)); fi
	if has_lowercase "$char"; then ((lowercase_count++)); fi
	if has_number "$char"; then ((number_count++)); fi
	if has_special "$char"; then ((special_count++)); fi
done


printf "%-10s %10s\n" "Uppercase" $uppercase_count
printf "%-10s %10s\n" "Lowercase" $lowercase_count
printf "%-10s %10s\n" "Number" $number_count
printf "%-10s %10s\n" "Special" $special_count


##--DONE 

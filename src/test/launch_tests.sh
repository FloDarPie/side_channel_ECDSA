#! /bin/bash

red_color="\033[31m"
green_color="\033[32m"
reset_color="\033[0m"

current_dir=$(pwd)

echo "Looking for tests in directory: ${current_dir}"

pattern='*_test.sage'
nb_test=$(find . -name "$pattern" | wc -l)

if [ "$nb_test" -eq "0" ]
then
    echo -ne "${red_color}exiting: no test file found with pattern $pattern\n${reset_color}"
    exit 1
else
    echo -ne "$nb_test test files found, entering venv and running them.\n"
fi

test_files=$(find . -name "$pattern")

progress=0
total_steps=$nb_test
bar_size=63 # looking good with unittest display

source ../../ecdsa_env/bin/activate

for test in $test_files; do

    let filled_slots=progress*bar_size/total_steps

    # Create the progress bar string
    bar=""
    for ((i=0; i<$filled_slots; i++)); do
        bar="${bar}#"
    done

    # Create the remaining bar string
    for ((i=$filled_slots; i<$bar_size; i++)); do
        bar="${bar}-"
    done

    let percentage=progress*100/total_steps

    # Print the progress bar
    echo -ne "\r[${green_color}${bar}${reset_color}] ${percentage}%\n"

    ((progress++)) # Updating progress

    echo "\$ ${test}"
    sage $test
done

# Print full bar
echo -ne "[${green_color}"
for ((i=0; i<$bar_size; i++)); do
        echo -ne "#"
done
echo -ne "${reset_color}] 100%\n"
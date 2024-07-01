#!/bin/bash
# This script was made to cleanup old music files for import. Remove non alphanumeric characters from all files in 
# the directory, recusively.

# Define a function to remove non-alphabet characters from the start of a filename
remove_non_alphabet() {
    local filename="$1"
    # Use regex to remove non-alphabet characters from the start of the filename
    new_filename=$(echo "$filename" | sed 's/^[^[:alpha:]]*//')
    # Rename the file
    mv "$filename" "$new_filename"
}

# Define a function to change into every directory recursively and list files
cd_and_list_files() {
    local directory="$1"
    
    # Change into the specified directory
    cd "$directory" || return
    
    # List files in the current directory
    echo "Files in directory: $PWD:"
    ls -p | grep -v /
    
    # read -r -p "Process? (y): " input
    input="y"

    if [ $input = "y" ]; then
        echo Processing...

        # Iterate over files in the current directory
        for file in *; do
            # Check if the file starts with a non-alphabet character
            if [[ "$file" =~ ^[^[:alpha:]] ]]; then
                # Call the function to remove non-alphabet characters from the filename
                remove_non_alphabet "$file"
            fi
        done

        echo Done. Though final result:
        echo ---------------
        ls -p | grep -v /
        echo ---------------
    else
        echo skipping...
    fi

    # Loop through directories in the current directory
    for item in */; do
        if [ -d "$item" ]; then
            echo "Changing into directory: $item"
            # Change into the directory
            cd "$item" || return
            # Recursively call the function for subdirectories
            cd_and_list_files "$PWD"
            # Move back up to the parent directory after processing
            cd ..
        fi
    done
}

# Start changing into directories and listing files from the specified directory
cd_and_list_files "./"

#!/bin/bash

# Created by Matthew Hull on 5/4/19

# This script will run an OCR scan on scanned in PDF files and filter them into the correct folders.
# Required: homebrew, gcc, imagemagick, tesseract, ghostscript

# Create the needed variables
currentDate="$(date +"%Y-%m-%d")"
residentsPath="Residents"
receiptsPath="Receipts"
convertedPath="Converted"
logPath="Logs"
commaLength=1
totalNameLength=15
lengthBuffer=2
residentsLength=${#residentsPath}
residentsLength=$(( $residentsLength + $lengthBuffer ))
receiptsLength=${#receiptsPath}
receiptsLength=$(( $receiptsLength + $lengthBuffer ))

# Loop throguh each file in the receipts directory
for file in $receiptsPath/*.pdf ; do

    fileMoved="false"
    fileName=$(echo $file | cut -c $receiptsLength-)

    # Get the text from the pdf file
    convert -density 300 $file -depth 8 -strip -background white -alpha off temp.tiff  > /dev/null 2>&1
    tesseract temp.tiff $file -l eng  > /dev/null 2>&1

    # loop through each resident directory
    for directory in $residentsPath/*/ ; do

        direcroryName=$(echo $directory | cut -c $residentsLength-)

        # Build an array that splits the directory name at the comma
        IFS=',' read -r -a directoryArray <<< "$directory"
        
        # Fix the firstname variable
        firstName=$"${directoryArray[1]}"
        IFS='/' read -r -a firstNameArray <<< "$firstName"
        firstName=$"${firstNameArray[0]}"
        
        # Fix the lastName variable
        lastName=$"${directoryArray[0]}"
        IFS='/' read -r -a lastNameArray <<< "$lastName"
        lastName=$"${lastNameArray[1]}"

        # Fix the firstname so it's truncated to fit into 15 characters
        lastNameLength=(${#lastName})
        lastNameLength=$(( $lastNameLength + $commaLength ))
        firstNameLength=$(( $totalNameLength - $lastNameLength ))
        if [ "$firstNameLength" -gt "0" ]; then 
            firstName=$(echo $firstName | cut -c1-$firstNameLength)
        else
            firstName=""   
        fi
        
        # Look for the first and last name, if found move the pdf
        if grep --quiet "$lastName" $file.txt; then
            if grep --quiet "$firstName" $file.txt; then
                echo "$fileName moved to $direcroryName"
                mv "$file" "$directory"
                fileMoved="true"
                echo "$fileName moved to $direcroryName" >> "$logPath/Log-$currentDate.txt"
            else
                lastNameCount=0
                for tempDirectory in $residentsPath/*/ ; do
                    
                    # Build an array that splits the directory name at the comma
                    IFS=',' read -r -a tempDirectoryArray <<< "$tempDirectory"

                    # Fix the lastName variable
                    lastNameCheck=$"${tempDirectoryArray[0]}"
                    IFS='/' read -r -a tempLastNameArray <<< "$lastNameCheck"
                    lastNameCheck=$"${tempLastNameArray[1]}"

                    if [ "$lastNameCheck" == "$lastName" ]; then
                        lastNameCount=$[$lastNameCount +1 ]
                    fi

                done

                # If only one person with the last name exists move it there
                if [ "$lastNameCount" -eq "1" ]; then
                    echo "$fileName moved to $direcroryName - Last name Only"
                    mv "$file" "$directory"
                    fileMoved="true"
                    echo "$fileName moved to $direcroryName - Last name Only" >> "$logPath/Log-$currentDate.txt"
                fi
            fi
        fi
    done
    if [ "$fileMoved" == "false" ]; then
        echo "$fileName not moved"
        echo "$fileName not moved" >> "$logPath/Log-$currentDate.txt"
    fi
    mv $file.txt $convertedPath
done
rm temp.tiff
echo "Done"
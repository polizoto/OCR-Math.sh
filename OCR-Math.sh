#!/bin/bash
# Joseph Polizzotto
# 408-504-7404
# Version 0.0.1
# Instructions: From a directory containing PDF file(s) to convert, open a Terminal window and enter the path to the script. Then press ENTER.
# This script is designed to run on a Windows 10 (PC) device

if [ ! -n "$(find . -maxdepth 1 -name '*.pdf' -type f -print -quit)" ]; then

echo -ne '\n'

echo -e "\033[1;31mPDF files are not located in this directory. Exiting...\033[0m"

exit

fi

if [ ! -f /c/scripts/MathPix_Key.txt ]; then

echo -ne '\n'

read -rp "Enter your MathPix Key or type q to quit: " MathPix_Key

if [[ "$MathPix_Key" == "q" ]] ; then

exit

fi

## Check if credentials are valid

curl -sS -X GET -H "app_key: $MathPix_Key" 'https://api.mathpix.com/v3/pdf-results?per_page=100&from_date=2020-06-26T03%3A08%3A22.827Z' > ./check_ID.txt

if 	grep -q 'Invalid' ./check_ID.txt ; then

echo -ne '\n'

echo -e "\033[1;31mThe MathPix Key you entered is invalid. Please check and try again. Exiting...\033[0m"

rm ./check_ID.txt

exit

fi

##

if [ ! -d /c/scripts/ ]; then

mkdir /c/scripts/

fi

echo -e "$MathPix_Key" > /c/scripts/MathPix_Key.txt

fi

if [ ! -f /c/scripts/mathpix_ID.txt ]; then

echo -ne '\n'

read -rp "Enter your MathPix App ID or type q to quit: " MathPix_ID

if [[ "$MathPix_ID" == "q" ]] ; then

exit

fi

if [ ! -d /c/scripts/ ]; then

mkdir /c/scripts/

fi

curl -sS -X POST https://api.mathpix.com/v3/latex -H "app_id: $MathPix_ID" -H "app_key: $MathPix_Key" -H 'Content-Type: application/json' --data '{"src": "https://mathpix-ocr-examples.s3.amazonaws.com/limit.jpg", "formats": ["latex_simplified", "asciimath"]}' > ./check_ID.txt

if 	grep -q 'Invalid' ./check_ID.txt ; then

echo -ne '\n'

echo -e "\033[1;31mThe MathPix ID you entered is invalid. Please check and try again. Exiting...\033[0m"

rm ./check_ID.txt

exit

fi

echo -e "$MathPix_ID" > /c/scripts/MathPix_ID.txt

fi

echo -ne '\n'

ls --color --group-directories-first --color=auto

echo -ne '\n'

read -p "Is it OK to use this shellscript in this directory? (Y / N) " ans

if [ "$ans" != "y" ]

then

exit

fi

mkdir -p OCRed-PDF

for file in *.pdf; do
        basePath=${file%.*}
        baseName=${basePath##*/}
        export baseName
        TIMESTAMP=`date "+%m-%d-%Y %H:%M"`

# Get the number of pages in a PDF file

pdfinfo "$file" | grep -w 'Pages:' | perl -p -e 's/(Pages:.* )(\d)/$2/g' > ./OCRed-PDF/"$baseName"_page_number.txt

# Create variable with max pages from PDF file

MAX=`cat ./OCRed-PDF/"$baseName"_page_number.txt`

function pause {

echo -ne '\n'
 read -s -n 1 -p "$(echo -e "\033[1;44m$file\033[0m\x1B[49m\x1B[K") has been sent to the MathPix Server. Please wait a few moments and then press any key to continue . . ."
}

echo -ne '\n'

read -p "$(echo -e "\033[1;44m$file\033[0m\x1B[49m\x1B[K") contains $MAX pages. Would you still like to perform OCR? (Y/N):  " ans

if [ "$ans" = "y" ]
then
conversion=yes
else
conversion=no
fi

if [[ $conversion == yes ]] ; then

MathPix_ID=`cat /c/scripts/MathPix_ID.txt`

MathPix_Key=`cat /c/scripts/MathPix_Key.txt`

curl -sS --location --request POST https://api.mathpix.com/v3/pdf -H "app_id: $MathPix_ID" -H "app_key: $MathPix_Key" --form "file=@$file" --form 'options_json="{\"math_display_delimiters\": [\"$$\", \"$$\"], \"math_inline_delimiters\": [\"$\", \"$\"]}"' > ./OCRed-PDF/"$baseName"_id.txt

PDF_ID=`cat ./OCRed-PDF/"$baseName"_id.txt | grep -w 'pdf_id' | sed 's/\(.*\)\(pdf_id":"\)\(.*\)\("}\)/\3/g'`

while :; do

curl -sS -X GET -H "app_key: $MathPix_Key" "https://api.mathpix.com/v3/pdf/$PDF_ID" > ./OCRed-PDF/"$file"_status.txt

if 	grep -q 'status":"completed"' ./OCRed-PDF/"$file"_status.txt ; then

break

else

pause

fi

done

echo -e '\n'

echo -e "\033[1;44m$file\033[0m is finished processing!"

echo -ne '\n'

while true; do

read -p "Choose the format you wish to download: press $(echo -e "\033[1;44m1\033[0m\x1B[49m\x1B[K") (LaTeX), $(echo -e "\033[1;44m2\033[0m\x1B[49m\x1B[K") (Markdown), or $(echo -e "\033[1;44m3\033[0m\x1B[49m\x1B[K") (DOCX): " val
		
echo -ne "\n"

case $val in
1) 
	   format=tex
	   end_format=LaTeX
	   break
	   ;;
	   
2) 
	   format=mmd
	   end_format=Markdown
	   break
	   ;;	
3) 
	   format=docx
	   end_format=DOCX
	   break
	   ;;	
	*)
       echo -e "\033[1;31mError: Invalid entry\033[0m "$val". \033[1;31mYou must enter one of the following values: [1 - 3].\033[0m\n"
	   ;;

esac

done

curl -sS --location --request GET "https://api.mathpix.com/v3/pdf/$PDF_ID.$format" --header "app_key: $MathPix_Key" --header "app_id: $MathPix_ID" > ./OCRed-PDF/"$baseName"."$format"

mv "$file" "OCRed-PDF"
 
rm ./OCRed-PDF/"$baseName"_page_number.txt
 
rm ./OCRed-PDF/"$file"_status.txt
 
echo -ne "\033[1;44m$file\033[0m has been converted to \033[1;44m$end_format\033[0m format."
 
echo -ne '\n'

if [ ! -d ./OCRed-PDF/log.txt ]; then

touch ./OCRed-PDF/log.txt 

fi

# Print the name of the PDF file that was converted as well as the time to the log.txt file.

echo -e "\n"$file" (ID: "$PDF_ID") was converted on "$TIMESTAMP"\n" >> ./OCRed-PDF/log.txt

rm ./OCRed-PDF/"$baseName"_id.txt

fi
 
done
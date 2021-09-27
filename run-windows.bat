:: Don't show these commands to the user
@echo off
:: Keep variables local, and expand at execution time not parse time
setlocal enabledelayedexpansion
:: Set the title of the window
title Electric Book

:: Start and reset a bunch of variables
:begin
set process=0
set bookfolder=
set subdirectory=
set config=
set imageset=
set imageconfig=
set repeat=
set baseurl=
set location=
set firstfile=
set epubIncludeMathJax=
set print-pdf-mathjax=
set screen-pdf-mathjax=
set webmathjax=
set appmathjax=
set searchIndexToRefresh=

:: Ask what we're going to be doing.
echo Electric Book options
echo ---------------------
echo.
echo 1  Create a print PDF
echo 1a Create a print PDF using AH Formatter
echo 2  Create a screen PDF
echo 3  Run as a website
echo 4  Create an epub
echo 5  Create an app
echo 6  Export to Word
echo 7  Convert source images to output formats
echo 8  Refresh search and book-index databases
echo 9  Install or update dependencies
echo x  Exit
echo.
set /p process=Enter a number and hit return. 
    if "%process%"=="1" goto printpdf
    if "%process%"=="1a" goto printahf
    if "%process%"=="2" goto screenpdf
    if "%process%"=="3" goto website
    if "%process%"=="4" goto epub
    if "%process%"=="5" goto app
    if "%process%"=="6" goto word
    if "%process%"=="7" goto convertimages
    if "%process%"=="8" goto refreshSearchIndex
    if "%process%"=="9" goto install
    if "%process%"=="x" goto:EOF
    goto choose

    :: :: :: :: :: ::
    :: PRINT PDF   ::
    :: :: :: :: :: ::

    :printpdf

        :: Encouraging message
        echo.
        echo Okay, let's make a print-ready PDF.
        echo.

        :: Remember where we are by assigning a variable to the current directory
        set location=%~dp0

        :: Ask user which folder to process
        :printpdfchoosefolder
            set /p bookfolder=Which book folder are we processing? (Hit enter for default 'book' folder.) 
            if "%bookfolder%"=="" set bookfolder=book
            if not exist "%bookfolder%\*.*" echo Sorry, %bookfolder% doesn't exist. Try again. && goto printpdfchoosefolder
            echo.

        :: Ask if we're outputting the files from a subdirectory
        :printpdfwhatsubdirectory
            set /p subdirectory=If you're outputting files in a subdirectory (e.g. a translation), type its name. Otherwise, hit enter. 
            if not exist "%bookfolder%\%subdirectory%\*.*" echo Sorry, %bookfolder%\%subdirectory% doesn't exist. Try again. && goto printpdfwhatsubdirectory
            echo.

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
        :print-pdf-otherconfigs
            echo.
            echo Any extra config files?
            echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
            echo _configs/_config.myconfig.yml
            echo If not, just hit return.
            echo.
            set /p config=
            echo.

        :: Ask if we're processing MathJax, so we know whether to process the HTML
            echo Does this book use MathJax? If yes, enter y. If no, just hit enter. 
            set /p print-pdf-mathjax=

        :: Loop back to this point to refresh the build and PDF
        :printpdfrefresh

            :: let the user know we're on it!
            echo Generating HTML...

            :: ...and run Jekyll to build new HTML
            :: with MathJax enabled if necessary
            if not "%print-pdf-mathjax%"=="y" goto printpdfnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.print-pdf.yml,_configs/_config.mathjax-enabled.yml,%config%" || exit /b
            goto printpdfjekylldone

            :: Build Jekyll without MathJax
            :printpdfnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.print-pdf.yml,%config%" || exit /b

            :printpdfjekylldone

            :: Skip the next step if we're not using MathJax.
            if not "%print-pdf-mathjax%"=="y" goto printpdfaftermathjax

            :: Convert all MathJax LaTeX to MathML
            if "%subdirectory%"=="" call gulp mathjax --book %bookfolder%
            if not "%subdirectory%"=="" call gulp mathjax --book %bookfolder% --language %subdirectory%
            cd "%location%"

            :printpdfaftermathjax

            :: Pre-process HTML for book indexes
            echo Creating targets for book-index references...
            if "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder%
            if not "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder% --language %printpdfsubdirectory%

            echo Adding link references to book indexes...
            if "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --output printpdf
            if not "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --language %printpdfsubdirectory% --output printpdf

            :: Navigate into the book's folder in _site output
            cd _site\%bookfolder%\"%subdirectory%\text"

            :: Let the user know we're now going to make the PDF
            echo Creating PDF...

            :: Check if the _output folder exists, or create it if not.
            :: (this check is currently not working in some setups, disabling it)
            rem if not exist ..\..\..\_output\nul
            rem mkdir ..\..\..\_output

            :: Run prince, showing progress (-v), printing the docs in file-list
            :: and saving the resulting PDF to the _output folder
            :: (For some reason this has to be run with call)
            set print-pdf-filename=%bookfolder%-%subdirectory%-print
            if "%subdirectory%"=="" set print-pdf-filename=%bookfolder%-print
	    call prince -v -l file-list -o "%location%_output\%print-pdf-filename%.pdf" --javascript

            :: Navigate back to where we began.
            cd "%location%"

            :: Tell the user we're done
            echo Done! Opening PDF...

            :: Navigate to the _output folder...
            cd _output

            :: and open the PDF we just created 
            :: (`start` so the PDF app opens as a separate process, doesn't hold up this script)
            start %print-pdf-filename%.pdf

            :: Navigate back to where we began.
            cd ..\

        :: Let the user easily refresh the PDF by running jekyll b and prince again
        set repeat=
        set /p repeat=Enter to run again, or any other key and enter to stop. 
        if "%repeat%"=="" goto printpdfrefresh
        echo.
        goto begin


    :: :: :: :: :: :: :: :: :: :: :: ::
    :: PRINT PDF USING AH Formatter  ::
    :: :: :: :: :: :: :: :: :: :: :: ::

    :printahf

        :: Encouraging message
        echo.
        echo Okay, let's make a print-ready PDF.
        echo.

        :: Remember where we are by assigning a variable to the current directory
        set location=%~dp0

        :: Ask user which folder to process
        :printahfchoosefolder
            set /p bookfolder=Which book folder are we processing? (Hit enter for default 'book' folder.) 
            if "%bookfolder%"=="" set bookfolder=book
            if not exist "%bookfolder%\*.*" echo Sorry, %bookfolder% doesn't exist. Try again. && goto printahfchoosefolder
            echo.

        :: Ask if we're outputting the files from a subdirectory
        :printahfwhatsubdirectory
            set /p subdirectory=If you're outputting files in a subdirectory (e.g. a translation), type its name. Otherwise, hit enter. 
            if not exist "%bookfolder%\%subdirectory%\*.*" echo Sorry, %bookfolder%\%subdirectory% doesn't exist. Try again. && goto printahfwhatsubdirectory
            echo.

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-ahf.yml
        :print-ahf-otherconfigs
            echo.
            echo Any extra config files?
            echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
            echo _configs/_config.myconfig.yml
            echo If not, just hit return.
            echo.
            set /p config=
            echo.

        :: Ask if we're processing MathJax, so we know whether to process the HTML
            echo Does this book use MathJax? If yes, enter y. If no, just hit enter. 
            set /p print-ahf-mathjax=

        :: Loop back to this point to refresh the build and PDF
        :printahfrefresh

            :: let the user know we're on it!
            echo Generating HTML...

            :: ...and run Jekyll to build new HTML
            :: with MathJax enabled if necessary
            if not "%print-ahf-mathjax%"=="y" goto printahfnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.print-pdf.yml,_configs/_config.mathjax-enabled.yml,%config%" || exit /b
            goto printahfjekylldone

            :: Build Jekyll without MathJax
            :printahfnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.print-pdf.yml,%config%" || exit /b

            :printahfjekylldone

            :: Skip the next step if we're not using MathJax.
            if not "%print-ahf-mathjax%"=="y" goto printahfaftermathjax

            :: Convert all MathJax LaTeX to MathML
            if "%subdirectory%"=="" call gulp mathjax --book %bookfolder%
            if not "%subdirectory%"=="" call gulp mathjax --book %bookfolder% --language %subdirectory%
            cd "%location%"

            :printahfaftermathjax

            :: Pre-process HTML for book indexes
            rem echo Creating targets for book-index references...
            rem if "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder%
            rem if not "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder% --language %printahfsubdirectory%

            rem echo Adding link references to book indexes...
            rem if "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --output printpdf
            rem if not "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --language %printahfsubdirectory% --output printpdf

            :: Navigate into the book's folder in _site output
            cd _site\%bookfolder%\"%subdirectory%\text"

            :: Check if the _output folder exists, or create it if not.
            :: (this check is currently not working in some setups, disabling it)
            rem if not exist ..\..\..\_output\nul
            rem mkdir ..\..\..\_output

            set print-ahf-filename=%bookfolder%-%subdirectory%-print

            :: Let the user know we're merging HTMLs.
            echo Merging into single HTML file...

	    if "%subdirectory%"=="" set print-ahf-filename=%bookfolder%-print

	    call node %location%/node_modules/xslt3/xslt3.js -it -xsl:%location%/_tools/xslt/eb2ahf.xsl -o:out.html file-list="file:///%location%_site/%bookfolder%/%subdirectory%text/file-list"

            :: Let the user know we're now going to make the PDF
            echo Creating PDF...

            :: Run AH Formatter, showing progress (-pgbar),
            :: and saving the resulting PDF to the _output folder.
	    :: 'formatter-config.xml' enables responsive SVG sizing.
            AHFCmd -pgbar -x 4 -d out.html -o "%location%_output\%print-ahf-filename%.pdf" -i "%location%_tools\ahf\formatter-config.xml"

            :: Navigate back to where we began.
            cd "%location%"

            :: Tell the user we're done
            echo Done! Opening PDF...

            :: Navigate to the _output folder...
            cd _output

            :: and open the PDF we just created 
            :: (`start` so the PDF app opens as a separate process, doesn't hold up this script)
            start %print-ahf-filename%.pdf

            :: Navigate back to where we began.
            cd ..\

        :: Let the user easily refresh the PDF by running jekyll b and prince again
        set repeat=
        set /p repeat=Enter to run again, or any other key and enter to stop. 
        if "%repeat%"=="" goto printahfrefresh
        echo.
        goto begin


    :: :: :: :: :: ::
    :: SCREEN PDF  ::
    :: :: :: :: :: ::

    :screenpdf

        :: Encouraging message
        echo.
        echo Okay, let's make a screen PDF.
        echo.

        :: Remember where we are by assigning a variable to the current directory
        set location=%~dp0

        :: Ask user which folder to process
        :screenpdfchoosefolder
            set /p bookfolder=Which book folder are we processing? (Hit enter for default 'book' folder.) 
            if "%bookfolder%"=="" set bookfolder=book
            if not exist "%bookfolder%\*.*" echo Sorry, %bookfolder% doesn't exist. Try again. && goto screenpdfchoosefolder
            echo.

        :: Ask if we're outputting the files from a subdirectory
        :screenpdfwhatsubdirectory
            set /p subdirectory=If you're outputting files in a subdirectory (e.g. a translation), type its name. Otherwise, hit enter. 
            if not exist "%bookfolder%\%subdirectory%\*.*" echo Sorry, %bookfolder%\%subdirectory% doesn't exist. Try again. && goto screenpdfwhatsubdirectory
            echo.

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
        :screen-pdf-otherconfigs
            echo.
            echo Any extra config files?
            echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
            echo _configs/_config.myconfig.yml
            echo If not, just hit return.
            echo.
            set /p config=
            echo.

        :: Ask if we're processing MathJax, so we know whether to process the HTML
        echo Does this book use MathJax? If yes, enter y. If no, just hit enter. 
        set /p screen-pdf-mathjax=

        :: Loop back to this point to refresh the build and PDF
        :screenpdfrefresh

            :: let the user know we're on it!
            echo Generating HTML...

            :: ...and run Jekyll to build new HTML
            :: with MathJax enabled if necessary
            if not "%screen-pdf-mathjax%"=="y" goto screenpdfnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.screen-pdf.yml,_configs/_config.mathjax-enabled.yml,%config%" || exit /b
            goto screenpdfjekylldone
            :screenpdfnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.screen-pdf.yml,%config%" || exit /b
            :screenpdfjekylldone

            :: Skip the next step if we're not using MathJax.
            if not "%screen-pdf-mathjax%"=="y" goto screenpdfaftermathjax

            :: Convert all MathJax LaTeX to MathML
            if "%subdirectory%"=="" call gulp mathjax --book %bookfolder%
            if not "%subdirectory%"=="" call gulp mathjax --book %bookfolder% --language %subdirectory%
            cd "%location%"

            :screenpdfaftermathjax

            :: Pre-process HTML for book indexes
            echo Creating targets for book-index references...
            if "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder%
            if not "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder% --language %screenpdfsubdirectory%

            echo Adding link references to book indexes...
            if "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --output screenpdf
            if not "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --language %screenpdfsubdirectory% --output screenpdf

            :: Navigate into the book's folder in _site output
            cd _site\%bookfolder%\"%subdirectory%\text"

            :: Let the user know we're now going to make the PDF
            echo Creating PDF...

            :: Run prince, showing progress (-v), printing the docs in file-list
            :: and saving the resulting PDF to the _output folder
            :: (For some reason this has to be run with call)
            set screen-pdf-filename=%bookfolder%-%subdirectory%-screen
            if "%subdirectory%"=="" set screen-pdf-filename=%bookfolder%-screen
            call prince -v -l file-list -o "%location%_output\%screen-pdf-filename%.pdf" --javascript

            :: Navigate back to where we began.
            cd "%location%"

            :: Tell the user we're done
            echo Done! Opening PDF...

            :: Navigate to the _output folder...
            cd _output

            :: and open the PDF we just created 
            :: (`start` so the PDF app opens as a separate process, doesn't hold up this script)
            start %screen-pdf-filename%.pdf

            :: Navigate back to where we began.
            cd ..\

        :: Let the user easily refresh the PDF by running jekyll b and prince again
        set repeat=
        set /p repeat=Enter to run again, or any other key and enter to stop. 
        if "%repeat%"=="" goto screenpdfrefresh
        echo.
        goto begin


    :: :: :: :: :: ::
    :: WEBSITE     ::
    :: :: :: :: :: ::

    :website

        :: Encouraging message
        echo Okay, let's make a website.

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
        echo.
        echo Any extra config files?
        echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
        echo _configs/_config.myconfig.yml
        echo If not, just hit return.
        echo.
        set /p config=
        echo.

        :: Ask the user to set a baseurl if needed
        echo Do you need to set a baseurl?
        echo If yes, enter it with no slashes at the start or end, e.g.
        echo my/base
        echo.
        set /p baseurl=
        echo.

        :: Ask if MathJax should be enabled.
        echo Do these books use MathJax? If yes, enter y. If no, hit enter.
        set /p webmathjax=

        :: let the user know we're on it!
        :webreadytoserve
        echo Getting your site ready...

        :: Two routes to go: with or without a baseurl
        if "%baseurl%"=="" goto servewithoutbaseurl

            :: Route 1, for serving with a baseurl
            :servewithbaseurl

                :: Run Jekyll, with MathJax enabled if necessary
                if not "%webmathjax%"=="y" goto webnomathjax
                call bundle exec jekyll serve --config="_config.yml,_configs/_config.web.yml,_configs/_config.mathjax-enabled.yml,%config%" --baseurl="/%baseurl%"
                goto webjekyllservedwithbaseurl

                :webnomathjax
                call bundle exec jekyll serve --config="_config.yml,_configs/_config.web.yml,%config%" --baseurl="/%baseurl%"

                :webjekyllservedwithbaseurl

                :: And we're done here
                goto websiterepeat

            :: Route 2, for serving without a baseurl
            :servewithoutbaseurl

                :: Run Jekyll, with MathJax enabled if necessary
                if not "%webmathjax%"=="y" goto webnomathjax
                call bundle exec jekyll serve --config="_config.yml,_configs/_config.web.yml,_configs/_config.mathjax-enabled.yml,%config%"
                goto webjekyllservednobaseurl
                :webnomathjax
                call bundle exec jekyll serve --config="_config.yml,_configs/_config.web.yml,%config%"

                :webjekyllservednobaseurl

        :: Let the user rebuild and restart
        :: 
        :: TO DO: This is not yet working. The script ends when you Ctrl-C to stop the website.
        :: 
        :websiterepeat
            set repeat=
            set /p repeat=Enter to restart the website process, or any other key and enter to stop. 
            if "%repeat%"=="" goto webreadytoserve
            echo.
            goto begin


    :: :: :: :: :: ::
    :: EPUB        ::
    :: :: :: :: :: ::

    :epub

        :: Encouraging message
        echo Okay, let's make an epub of %bookfolder%...
        :: Remember where we are by assigning a variable to the current directory
        set location=%~dp0
        
        :: Ask user which folder to process
        :epubchoosefolder
            set /p bookfolder=Which book folder are we processing? (Hit enter for default 'book' folder.) 
            if "%bookfolder%"=="" set bookfolder=book
            if not exist "%bookfolder%\*.*" echo Sorry, %bookfolder% doesn't exist. Try again. && goto epubchoosefolder
        
        :: Ask if we're outputting the files from a subdirectory
        :epubwhatsubdirectory
            echo If you're outputting files in a subdirectory (e.g. a translation), type its name. Otherwise, hit enter. 
            set /p subdirectory=
            if not exist "%bookfolder%\%subdirectory%\*.*" echo Sorry, %bookfolder%\%subdirectory% doesn't exist. Try again. doesn't exist. && goto epubwhatsubdirectory
        
        :: Ask whether to include boilerplate mathjax directory
        :epubAskToIncludeMathJax
            echo Include mathjax? Enter y for yes (or hit enter for no).
            set /p epubIncludeMathJax=
            if "%epubIncludeMathJax%"=="n" set epubIncludeMathJax=
            if not "%epubIncludeMathJax%"=="y" if not "%epubIncludeMathJax%"=="" goto epubAskToIncludeMathJax

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
        :epubAskForConfigFiles
            echo Any extra config files?
            echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
            echo _configs/_config.myconfig.yml
            echo If not, just hit return.
            set /p config=

        :: Ask about validation
        :epubAskAboutValidation
            set epubValidation=
            echo Shall we try to run EpubCheck when we're done? Hit enter for yes, or any key and enter for no.
            set /p epubValidation=

        :: Loop back to this point to refresh the build again
        :epubrefresh

        :: Let the user know we're on it!
        if "%subdirectory%"=="" goto epubGeneratingHTMLNoSubdirectory
        if not "%subdirectory%"=="" goto epubGeneratingHTMLWithSubdirectory

        :epubGeneratingHTMLNoSubdirectory
            echo Generating HTML for %bookfolder%.epub...
            goto epubJekyllBuild

        :epubGeneratingHTMLWithSubdirectory
            echo Generating HTML for %bookfolder%-%subdirectory%.epub...
            goto epubJekyllBuild

        :: ...and run Jekyll to build new HTML
        :epubJekyllBuild
            if "%epubIncludeMathJax%"=="y" call bundle exec jekyll build --config="_config.yml,_configs/_config.epub.yml,_configs/_config.mathjax-enabled.yml,%config%" || exit /b
            if not "%epubIncludeMathJax%"=="y" call bundle exec jekyll build --config="_config.yml,_configs/_config.epub.yml,%config%" || exit /b
            echo HTML generated.
            :epubJekyllDone

        :: Pre-process HTML for book indexes
        echo Creating targets for book-index references...
        if "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder%
        if not "%subdirectory%"=="" call gulp renderIndexCommentsAsTargets --book %bookfolder% --language %epubsubdirectory%

        echo Adding link references to book indexes...
        if "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --output epub
        if not "%subdirectory%"=="" call gulp renderIndexListReferences --book %bookfolder% --language %epubsubdirectory% --output epub

        :: What's next?
        echo Assembling epub...


        :: Copy styles, images, text, package.opf and toc.ncx to epub folder.
        :: The echo f preemptively answers xcopy's question whether 
        :: this is a file (see https://stackoverflow.com/a/3018371).
        :: The > nul supresses command-line feedback (pseudo silent mode)
        cd _site\%bookfolder%


        :: Test copying options
        :epubCopyStyles
            echo Copying styles...
            :: --------------------------
            :: If original language output: copy original styles files only
            if "%subdirectory%"=="" if not exist %subdirectory%\styles\*.* goto epubOriginalStyles
            :: Translation output, but no translated-styles subdirectory for that translation:
            :: copy the original styles files only
            if not "%subdirectory%"=="" if not exist %subdirectory%\styles\*.* goto epubOriginalStyles
            :: Translation output, and translation styles for that translation exist:
            :: create folder structure, and copy the styles in that translation folder, too
            if not "%subdirectory%"=="" if exist %subdirectory%\styles\*.* goto epubTranslationStyles

        :: Copy original styles
        :epubOriginalStyles
            xcopy /i /q "styles\*.css" "..\epub\%bookfolder%\styles" > nul
            xcopy /i /q "%location%\_site\assets\styles\*.css" "..\epub\%bookfolder%\assets\styles" > nul
            :: Done! Move along to moving the text folder
            echo Styles copied.
            goto epubCopyImages
        
        :: Copy translated styles, in addition to original styles
        :epubTranslationStyles
            xcopy /i /q "styles\*.css" "..\epub\%bookfolder%\styles" > nul
            mkdir "..\epub\%subdirectory%\styles"
            if exist "%subdirectory%\styles\*.css" xcopy /i /q "%bookfolder%\%subdirectory%\styles\*.css" "..\epub\%bookfolder%\%subdirectory%\styles" > nul
            :: Done! Move along to moving the text folder
            echo Translation styles copied.
            goto epubCopyImages


        :: Test copying options
        :epubCopyImages
            echo Copying images...
            :: --------------------------
            :: If original language output: copy only files in images/epub
            if "%subdirectory%"=="" if not exist %subdirectory%\images\*.* goto epubOriginalImages
            :: Translation output, but no translated-images subdirectory for that translation:
            :: copy the original images files only
            if not "%subdirectory%"=="" if not exist %subdirectory%\images\*.* goto epubOriginalImages
            :: Translation output, and an images subdir for that translation exists:
            :: create folder structure, and copy only the images in that translation folder
            if not "%subdirectory%"=="" if exist %subdirectory%\images\*.* goto epubTranslationImages

        :: Copy original images
        :epubOriginalImages
            xcopy /i /q "images\epub\*.*" "..\epub\%bookfolder%\images\epub" > nul
            xcopy /i /q "%location%\_site\items\images\epub\*.*" "..\epub\items\images\epub"
            xcopy /i /q "%location%\_site\assets\images\epub\*.*" "..\epub\assets\images\epub" > nul
            :: Done! Move along to moving the text folder
            echo Images copied.
            goto epubCopyText
        
        :: Copy translated images, after deleting original images
        :epubTranslationImages
            rd /s /q images
            mkdir "..\epub\%subdirectory%\images\epub"
            xcopy /i /q "%subdirectory%\images\epub\*.*" "..\epub\%bookfolder%\%subdirectory%\images\epub" > nul
            xcopy /i /q "%location%\_site\items\%subdirectory%\images\epub\*.*" "..\epub\items\%subdirectory%\images\epub" > nul
            :: Done! Move along to moving the text folder
            echo Images copied.
            goto epubCopyText


        :: Copy contents of text or text/subdirectory to epub/bookfolder/text.
        :: We don't want all the files in text, we only want the ones
        :: in the epub file list.
        :epubCopyText
            echo Copying text...

        :: If this isn't a translation, skip ahead to epubCopyNoSubdirectory 
        if "%subdirectory%"=="" goto epubOriginalText

        :: Copy the contents of the subdirectory
        :epubSubdirectoryText
            rd /s /q "text"
            mkdir "..\epub\%bookfolder%\%subdirectory%\text"
            cd %subdirectory%\text
            for /F "tokens=* skip=1" %%i in (file-list) do xcopy /q %%i "..\..\..\epub\%bookfolder%\%subdirectory%\text\" > nul
            cd ..
            cd ..
            echo Text copied.
            goto epubCopyOPF

        :: Copy the files in file-list from the original text folder
        :epubOriginalText
            cd text
            for /F "tokens=* skip=1" %%i in (file-list) do xcopy /q %%i "..\..\epub\%bookfolder%\text\" > nul
            cd ..
            echo Text copied.
            goto epubCopyOPF


        :: Get the right package.opf for the translation we're creating
        :epubCopyOPF
            echo Copying package file...
            if "%subdirectory%"=="" goto epubOriginalOPF
            if not "%subdirectory%"=="" goto epubSubdirectoryOPF

        :: If original language, use the package.opf in the root
        :epubOriginalOPF
            echo f | xcopy /q "package.opf" "../epub" > nul
            echo Package file copied.
            goto epubOPFDone

        :: If translation language, use the package.opf in the subdirectory
        :: This will overwrite the original language OPF file
        :epubSubdirectoryOPF
            echo f | xcopy /q "%subdirectory%\package.opf" "../epub" > nul
            echo Package file copied.
            goto epubOPFDone

        :epubOPFDone


        :: Get the right toc.ncx for the translation we're creating
        :epubCopyNCX
            echo Copying NCX file...
            if "%subdirectory%"=="" goto epubOriginalNCX
            if not "%subdirectory%"=="" goto epubSubdirectoryNCX

        :: If original language, use the package.opf in the root
        :epubOriginalNCX
            echo f | xcopy /q "toc.ncx" "../epub" > nul
            echo NCX copied.
            goto epubNCXDone

        :: If translation language, use the toc.ncx in the subdirectory
        :: This will overwrite the original language NCX file
        :epubSubdirectoryNCX
            echo f | xcopy /q "%subdirectory%\toc.ncx" "../epub" > nul
            echo NCX copied.
            goto epubNCXDone

        :epubNCXDone

        :: Go into _site/epub to move some more files and then zip to _output
        cd %location%_site/epub

        :: Copy the bundle.js into the epub folder
        :epubMoveJS
            echo Copying Javascript to epub...
            robocopy "%location%_site/assets/js" "%location%_site/epub/assets/js" bundle.js /E /NFL /NDL /NJH /NJS /NC /NS
            echo Javascript copied.

        :: If there is a fonts folder, and it has no contents, delete it.
        :: Otherwise, if this is a translation, move the fonts folder
        :: into the subdirectory alongside text, images, styles.
        :epubMoveFonts
            echo Checking for epub fonts...
            if exist "fonts" if not exist "fonts\*.ttf" if not exist "fonts\*.otf" if not exist "fonts\*.woff" if not exist "fonts\*.woff2" rd /s /q "fonts"

            :: Copy only *epub* fonts to assets/fonts
            xcopy /i /q "%location%\_site\epub\fonts\*.*" "%location%\_site\epub\assets\fonts" > nul
            echo Fonts checked.

        :: If MathJax required, fetch boilerplate mathjax directory from /assets/js
        :: (MathJax lives in the root directory even in translations.)
        if "%epubIncludeMathJax%"=="y" goto epubGetMathjax
        goto epubSetFilename

        :epubGetMathjax
            echo Copying MathJax to epub...
            :: Copy mathjax folder from /assets/js to _site/epub
            :: Suppress the console output with /NFL /NDL /NJH /NJS /NC /NS
            :: Adding /NP will also suppress progress bar.
            robocopy "%location%_site/assets/js/mathjax" "%location%_site/epub/assets/js/mathjax" /E /NFL /NDL /NJH /NJS /NC /NS

        :: Set the filename of the epub, sans file extension
        :epubSetFilename
            if "%subdirectory%"=="" set epubFileName=%bookfolder%
            if not "%subdirectory%"=="" set epubFileName=%bookfolder%-%subdirectory%

        :: If they exist, remove previous .zip and .epub files that we will replace.
        echo Removing any previous epub-build, %epubFileName%.zip and %epubFileName%.epub files...
        if exist "%location%\_output\%epubFileName%" rd /s /q "%location%\_output\%epubFileName%"
        if exist "%location%\_output\%epubFileName%.zip" del /q "%location%\_output\%epubFileName%.zip"
        if exist "%location%\_output\%epubFileName%.epub" del /q "%location%\_output\%epubFileName%.epub"
        echo Removed any previous zip and epub files.

        :: Remove any empty folders
        :: (Thanks https://superuser.com/a/972366/491948)
        :: Suppress the console output with /NFL /NDL /NJH /NJS /NC /NS
        :: Adding /NP will also suppress progress bar.
        :epubRemoveEmptyFolders
            echo Removing empty folders...
            :: Step out of the folder temporarily to avoid robocopy error messages
            cd %location%
            robocopy %location%/_site/epub/ %location%/_site/epub /s /move /NFL /NDL /NJH /NJS /NC /NS /NP
            :: Now step back into the folder before continuing
            cd %location%/_site/epub

        :: Rename .html to .xhtml in files and links
        :epubRenameHtmlXhtml
            echo Renaming .html to .xhtml...

            cd %location%
            if "%subdirectory%"=="" call gulp epub:xhtmlLinks --book %bookfolder%
            if "%subdirectory%"=="" call gulp epub:xhtmlFiles --book %bookfolder%
            if "%subdirectory%"=="" call gulp epub:cleanHtmlFiles --book %bookfolder%
            if not "%subdirectory%"=="" call gulp epub:xhtmlLinks --book %bookfolder% --language %subdirectory%
            if not "%subdirectory%"=="" call gulp epub:xhtmlFiles --book %bookfolder% --language %subdirectory%
            if not "%subdirectory%"=="" call gulp epub:cleanHtmlFiles --book %bookfolder% --language %subdirectory%
            cd %location%/_site/epub

        :: Now to zip the epub files. Important: mimetype first.
        :epubCompressing
            echo Assembling epub files...

            :: Copy root folders
            if exist "%bookfolder%\images\epub" robocopy "%location%\_site\epub\%bookfolder%\images\epub" "%location%_output\%epubFileName%\%bookfolder%\images\epub" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist "items" robocopy "%location%\_site\epub\items" "%location%\_output\%epubFileName%\items" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist "fonts" robocopy "%location%\_site\epub\fonts" "%location%\_output\%epubFileName%\assets\fonts" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist "%bookfolder%\styles" robocopy "%location%\_site\epub\%bookfolder%\styles" "%location%\_output\%epubFileName%\%bookfolder%\styles" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist "assets\images\epub\*.*" robocopy "%location%\_site\epub\assets\images" "%location%\_output\%epubFileName%\assets\images" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist "assets\js\mathjax" robocopy "%location%\_site\epub\assets\js\mathjax" "%location%\_output\%epubFileName%\assets\js\mathjax" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist "assets\js" robocopy "%location%\_site\epub\assets\js" "%location%\_output\%epubFileName%\assets\js" /E /NFL /NDL /NJH /NJS /NC /NS

            :: Copy text directory if this is not a translation
            if not "%subdirectory%"=="" goto epubZipSubdirectory
            if exist "%bookfolder%\text" robocopy "%location%\_site\epub\%bookfolder%\text" "%location%\_output\%epubFileName%\%bookfolder%\text" /E /NFL /NDL /NJH /NJS /NC /NS
            goto epubAddPackageFiles

            :: And if it is a translation, move the language's text subdirectory
            :epubZipSubdirectory
                if not "%subdirectory%"=="" if exist "%bookfolder%\%subdirectory%\text" robocopy "%location%\_site\epub\%bookfolder%\%subdirectory%" "%location%\_output\%epubFileName%\%bookfolder%\%subdirectory%" /E /NFL /NDL /NJH /NJS /NC /NS
                goto epubAddPackageFiles

        :: Add the META-INF, package.opf and toc.ncx
        :epubAddPackageFiles
            :: Now add these admin files to the zip
            if exist META-INF robocopy "%location%\_site\epub\META-INF" "%location%\_output\%epubFileName%\META-INF" /E /NFL /NDL /NJH /NJS /NC /NS
            if exist package.opf robocopy "%location%\_site\epub" "%location%\_output\%epubFileName%" package.opf /E /NFL /NDL /NJH /NJS /NC /NS
            if exist toc.ncx robocopy "%location%\_site\epub" "%location%\_output\%epubFileName%" toc.ncx /E /NFL /NDL /NJH /NJS /NC /NS

        :: Zip the epub
        echo Zipping with Node...
		cd "%location%\_output"
        node "%location%/_tools/zip/zip.js" "%epubFileName%"

        :: Change file extension .zip to .epub
            cd %location%_output
            if exist %epubFileName%.zip ren %epubFileName%.zip %epubFileName%.epub

        :: We're done!
        :epubCreated
            if exist %epubFileName%.epub echo Epub created^^!
            if not exist %epubFileName%.epub echo Sorry, something went wrong.

        :: Check if epubcheck is in the PATH, and run it if it is
            if not "%epubValidation%"=="" goto skipepubValidation
            echo If EpubCheck is in your PATH, we'll run validation now.

            :: Use a batch-file trick to get the location of epubcheck
            :: https://blogs.msdn.microsoft.com/oldnewthing/20120731-00/?p=7003/
            for /f %%i in ('where epubcheck.jar') do set epubchecklocation=%%i
            if "%epubchecklocation%"=="" echo Couldn't find EpubCheck, sorry.
            if "%epubchecklocation%"=="" goto skipEpubValidation

            :: then run it, saving the error stream to a log file
            :: First, create a timestamp
            for /f "tokens=2-8 delims=.:/, " %%a in ("%date% %time%") do set timestamp=%%c-%%a-%%bT%%d-%%e-%%f
            set epubCheckLogFile=epubcheck-log-%timestamp%
            echo Found EpubCheck at %epubchecklocation%, running validation...
            call java -Xss1024k -jar %epubchecklocation% %epubFileName%.epub 2>> %epubCheckLogFile%.txt
            echo Opening EpubCheck log...
            start %epubCheckLogFile%.txt

        :: Skip to here if epubcheck wasn't found in the PATH
        :: or the user didn't want validation
        :skipEpubValidation

        :: Open file explorer to show the epub
        echo Opening folder containing your epub...
        %SystemRoot%\explorer.exe "%location%_output"

        :: Navigate back to where we began
        cd "%location%"

        :: Let the user easily run that again
        set repeat=
        set /p repeat=Enter to run again, or any other key and enter to stop. 
        if "%repeat%"=="" goto epubrefresh
        goto begin


    :: :: :: :: :: ::
    :: APP         ::
    :: :: :: :: :: ::

    :app

        :: Remember where we are by assigning a variable to the current directory
        set location=%~dp0

        :: Encouraging message
        echo Okay, let's make an Android app. First we'll generate the HTML,
        echo then we'll build an app. For the build, you need Cordova
        echo and Android Studio installed.
        echo.
        echo Shall we build the app, or just generate the HTML? Enter y to build the app, if not hit enter. 
        set /p appbuildgenerateapp=

        :: Are we building a release?
        echo Are you creating an app for release, or just for testing?
        echo Enter y for a release, otherwise just hit enter.
        set /p apprelease=

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
        echo.
        echo Any extra config files?
        echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
        echo _configs/_config.myconfig.yml
        echo If not, just hit return.
        echo.
        set /p config=
        echo.

        :: Ask if MathJax should be enabled.
        echo Do these books use MathJax? If yes, enter y. If no, hit enter.
        set /p appmathjax=

        :: Run Jekyll, with MathJax enabled if necessary
        :appbuildrepeat
            echo Building your HTML...
            if not "%appmathjax%"=="y" goto appbuildnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.app.yml,_configs/_config.mathjax-enabled.yml,%config%" || exit /b
            goto apphtmlbuilt
            :appbuildnomathjax
            call bundle exec jekyll build --config="_config.yml,_configs/_config.app.yml,%config%" || exit /b
            :apphtmlbuilt

            :: Put HTML into app/www by moving everything (/E) in _site
            :: excluding (/XD) the app folder itself, into app/www.
            :: Suppress the console output with /NFL /NDL /NJH /NJS /NC /NS
            :: Adding /NP will also suppress progress bar.
            :: (I'd remove the moved folders with /MOVE but that's not working.)
            echo Copying files to app directory...
            robocopy "%location%_site" "%location%_site/app/www" /E /XD "%location%_site\app" /NFL /NDL /NJH /NJS /NC /NS

            :: Build app with Cordova
            if not "%appbuildgenerateapp%"=="y" goto appbuildaftercordova
            echo Building your Android app... If you get an error, make sure Cordova and Android Studio are installed.
            cd _site/app

            :: Prepare for build
            echo Removing old Android platform files...
            call cordova platform remove android
            echo Fetching latest Android platform files...
            call cordova platform add android
            echo Preparing platforms and plugins...
            call cordova prepare android
            echo Building app...

            if "%apprelease%"=="y" (
                call cordova build android --release
            ) else (
                call cordova build android
            )

            echo Opening folder containing app...
            %SystemRoot%\explorer.exe "%location%_site\app\platforms\android\app\build\outputs\apk"

            :: Try to emulate
            echo "Attempting to run app in emulator..."
            call cordova emulate android

            :appbuildaftercordova
            cd "%location%"

        :: Let the user rebuild and restart
        :appbuildrepeatselect
            set repeat=
            set /p repeat=Enter to rebuild the app HTML, or any other key and enter to stop. 
            if "%repeat%"=="" goto appbuildrepeat
            echo.
            goto begin


    :: :: :: :: :: ::
    :: WORD EXPORT ::
    :: :: :: :: :: ::

    :word

        :: Encouraging message
        echo.
        echo Okay, let's export to Word.
        echo.

        :: Remember where we are by assigning a variable to the current directory
        set location=%~dp0

        :: Ask user which folder to process
        :wordwhatdirectory
            set /p bookfolder=Which book folder are we processing? (Hit enter for default 'book' folder.) 
            if "%bookfolder%"=="" set bookfolder=book
            if not exist "%bookfolder%\*.*" echo Sorry, %bookfolder% doesn't exist. Try again. && goto wordwhatdirectory

        :: Ask if we're outputting the files from a subdirectory
        :wordwhatsubdirectory
            set /p subdirectory=If you're outputting files in a subdirectory (e.g. a translation), type its name. Otherwise, hit enter. 
            if not exist "%bookfolder%\%subdirectory%\*.*" echo Sorry, %bookfolder%\%subdirectory% doesn't exist. Try again. && goto wordwhatsubdirectory
            echo.

        :: Ask user which output type to work from
        echo Which format are we converting from? Enter a number or hit enter for the default (screen PDF):
        echo 1. Print PDF
        echo 2. Screen PDF (default)
        echo 3. Web
        echo 4. Epub
        set /p fromformat=

        :: Turn that choice into the name of an output format for our config
        if "%fromformat%"=="" set fromformat=screen-pdf
        if "%fromformat%"=="1" set fromformat=print-pdf
        if "%fromformat%"=="2" set fromformat=screen-pdf
        if "%fromformat%"=="3" set fromformat=web
        if "%fromformat%"=="4" set fromformat=epub

        :: Ask the user to add any extra Jekyll config files, e.g. _config.images.print-pdf.yml
        echo.
        echo Any extra config files?
        echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
        echo _configs/_config.myconfig.yml
        echo If not, just hit return.
        echo.
        set /p config=
        echo.

        :: Loop back to this point to refresh the build again
        :wordrefresh

            :: let the user know we're on it!
            echo Generating HTML...

            :: ...and run Jekyll to build new HTML.
            :: We turn off the math engine so that we get raw TeX output,
            :: and because Pandoc does not support SVG output anyway.
            call bundle exec jekyll build --config="_config.yml,_configs/_config.%fromformat%.yml,_configs/_config.math-disabled.yml,%config%" || exit /b

            :: Navigate to the HTML we just generated
            if "%subdirectory%"=="" cd _site\%bookfolder%\text
            if not "%subdirectory%"=="" cd _site\%bookfolder%\%subdirectory%\text

            :: What're we doing?
            echo Converting %bookfolder% HTML to Word...

            :: We'll temporarily use a pandoc-specific file-list
            :: Remove previous file-list-pandoc if any
            if exist file-list-pandoc del file-list-pandoc

            :: Remove empty lines from file-list by selecting
            :: only the lines with '.html' in them. I.e. our files.
            findstr /r /c:".html" file-list > file-list-pandoc

            :: Loop through the list of files in file-list-pandoc
            :: and convert them each from .html to .docx.
            :: We end up with the same filenames, 
            :: with .docx extensions appended.
            for /F "tokens=*" %%F in (file-list-pandoc) do (
                pandoc %%F -f html -t docx -s -o %%F.docx
                )

            :: And then remove the temporary file we created
            del file-list-pandoc

            :: User feedback
            echo Fixing file extensions...

            :: We're going to find .html file extensions and replace them with nothing
            set find=.html
            set replace=

            :: Loop through all .docx files and remove the .html
            :: from those filenames pandoc created.
            for %%# in (.\*.docx) do (
                set "File=%%~nx#"
                ren "%%#" "!File:%find%=%replace%!"
            )

            :: User feedback
            echo Done, opening folder...

            :: Open file explorer to show the docx files.
            if "%subdirectory%"=="" %SystemRoot%\explorer.exe "%location%_site\%bookfolder%\text"
            if not "%subdirectory%"=="" %SystemRoot%\explorer.exe "%location%_site\%bookfolder%\%subdirectory%\text"

            :: Navigate back to where we began
            cd "%location%"

        :: Let the user easily run that again
        set repeat=
        set /p repeat=Enter to try again, or any other key and enter to stop. 
        if "%repeat%"=="" goto word
        echo.
        goto begin

    :: :: :: :: :: :: ::
    :: CONVERT IMAGES ::
    :: :: :: :: :: :: ::

    :convertimages

        :: Encouraging message, and explain
        echo Let's convert your source images.
        echo This process will optimise the images in a book's _source folder
        echo and copy them to the print-pdf, screen-pdf, web and epub image folders.
        echo You need to have run 'Install or update dependencies' at least once,
        echo have Gulp installed globally (https://gulpjs.com/),
        echo and have GraphicsMagick installed (http://www.graphicsmagick.org).
        echo.

        :: Select which book to convert images for
        :convertimagesselectbook
            set bookimagestoconvert=
            echo Which book's images are you converting? Hit enter for the default 'book'.
            set /p bookimagestoconvert=
            if "%bookimagestoconvert%"=="" set "bookimagestoconvert=book" && goto convertimageslanguageselect
            if not exist "%bookimagestoconvert%" echo Sorry, %bookimagestoconvert% doesn't exist. Try again. && goto convertimagesselectbook

        :: Select whether we're converting images for a translation
        :convertimageslanguageselect
            echo.
            echo Are we converting books in a translation? If not, hit enter.
            echo Otherwise, enter the language code/translation directory name. 
            set /p convertimageslanguage=
            if "%convertimageslanguage%"=="" goto convertimagescustombook
            if not exist "%bookimagestoconvert%\%convertimageslanguage%" echo Sorry, %bookimagestoconvert%\%convertimageslanguage% doesn't exist. Try again. && goto convertimageslanguageselect

        :: Run default gulp task
        :convertimagescustombook
            echo Converting images...
            call gulp --book "%bookimagestoconvert%" --language "%convertimageslanguage%"
            echo Done^!

        :: Back to the beginning
        :convertimagescomplete
            goto begin

    :: :: :: :: :: :: ::
    :: REFRESH SEARCH ::
    :: :: :: :: :: :: ::

    :refreshSearchIndex

        : Save where we are
        set location=%~dp0

        :: Encouraging message
        echo Let's refresh search and index databases.
        echo We'll index the files in your web or app file lists as defined in meta.yml.

        :: Check which format(s) to refresh
        echo Choose a format to refresh:
		echo 1 Print PDF
		echo 2 Screen PDF
		echo 3 Web
		echo 4 Epub
		echo 5 App
		echo Or hit enter for all formats
        set /p searchIndexToRefresh=

        :: Ask the user to add any extra Jekyll config files,
        :: e.g. _config.live.yml
        :searchIndexOtherConfigs
            echo.
            echo Any extra config files?
            echo Enter filenames (including any relative path), comma separated, no spaces. E.g.
            echo _configs/_config.live.yml
            echo If not, just hit return.
            echo.
            set /p searchIndexConfig=
            echo.

        :: Create blank index files if they don't exist
        :: Credit https://stackoverflow.com/a/211045/1781075
        if not exist "assets/js/book-index-print-pdf.js" copy /y NUL "assets/js/book-index-print-pdf.js" >NUL
        if not exist "assets/js/book-index-screen-pdf.js" copy /y NUL "assets/js/book-index-screen-pdf.js" >NUL
        if not exist "assets/js/book-index-web.js" copy /y NUL "assets/js/book-index-web.js" >NUL
        if not exist "assets/js/book-index-epub.js" copy /y NUL "assets/js/book-index-epub.js" >NUL
        if not exist "assets/js/book-index-app.js" copy /y NUL "assets/js/book-index-app.js" >NUL

        :: Generate HTML with Jekyll
        echo Generating HTML with Jekyll...
        if "%searchIndexToRefresh%"=="" goto buildAllIndexes
        if "%searchIndexToRefresh%"=="1" goto buildPrintPDFIndex
        if "%searchIndexToRefresh%"=="2" goto buildScreenPDFIndex
        if "%searchIndexToRefresh%"=="3" goto buildWebIndex
        if "%searchIndexToRefresh%"=="4" goto buildEpubIndex
        if "%searchIndexToRefresh%"=="5" goto buildAppIndex

        :buildAllIndexes
        :buildPrintPDFIndex

            call bundle exec jekyll build --config="_config.yml,_configs/_config.print-pdf.yml,%searchIndexConfig%" || exit /b

			:: Use gulp to render targets, so that Puppeteer does not,
			:: because we need targets added by the same engine (cheerio) that
			:: will populate the index list with links.
            call gulp renderIndexCommentsAsTargets
            call node _site/assets/js/render-book-index.js

            if not "%searchIndexToRefresh%"=="" goto refreshSearchIndexRendering

        :buildScreenPDFIndex

            call bundle exec jekyll build --config="_config.yml,_configs/_config.screen-pdf.yml,%searchIndexConfig%" || exit /b

			:: Use gulp to render targets, so that Puppeteer does not,
			:: because we need targets added by the same engine (cheerio) that
			:: will populate the index list with links.
            call gulp renderIndexCommentsAsTargets
            call node _site/assets/js/render-book-index.js

            if not "%searchIndexToRefresh%"=="" goto refreshSearchIndexRendering

        :buildWebIndex

            call bundle exec jekyll build --config="_config.yml,_configs/_config.web.yml,%searchIndexConfig%" || exit /b
            call node _site/assets/js/render-book-index.js
            call node _site/assets/js/render-search-index.js

            if not "%searchIndexToRefresh%"=="" goto refreshSearchIndexRendering

        :buildEpubIndex

            call bundle exec jekyll build --config="_config.yml,_configs/_config.epub.yml,%searchIndexConfig%" || exit /b

			:: Use gulp to render targets, so that Puppeteer does not,
			:: because we need targets added by the same engine (cheerio) that
			:: will populate the index list with links.
            call gulp renderIndexCommentsAsTargets
            call node _site/assets/js/render-book-index.js

            if not "%searchIndexToRefresh%"=="" goto refreshSearchIndexRendering

        :buildAppIndex

            call bundle exec jekyll build --config="_config.yml,_configs/_config.app.yml,%searchIndexConfig%" || exit /b
            call node _site/assets/js/render-book-index.js
            call node _site/assets/js/render-search-index.js

            if not "%searchIndexToRefresh%"=="" goto refreshSearchIndexRendering

        :: Run script from scripts directory
        :refreshSearchIndexRendering

            echo Generating index...
            cd %location%
            node _site/assets/js/render-search-index.js

        :: Done
        :refreshSearchIndexDone

            echo Indexing done.
            goto begin

    :: :: :: :: :: ::
    :: INSTALL     ::
    :: :: :: :: :: ::

    :install

        :: Encouraging message
        echo Let's install gems and update some dependencies.

        :: Check if Bundler is installed. If not, install it.
        :: (Thanks http://stackoverflow.com/a/4781795/1781075)
        echo First, we're going to run Bundler to update and install dependencies. 
        echo If Bundler is not already installed, we'll install it first.
        echo If you get a rubygems error about SSL certificate failure, see
        echo http://guides.rubygems.org/ssl-certificate-update/
        echo This may take a few minutes.
        set found=
        for %%e in (%pathext%) do (
          for %%X in (bundler%%e) do (
            if not defined found (
              set found=%%~$PATH:X
            )
          )
        )
        if not "%found%"=="" goto bundlerinstalled
        if "%found%"=="" echo Installing Bundler...
        gem install bundler
        :bundlerinstalled

        :: Run bundle update
        echo Updating Bundler...
        call bundle update

        :: Run bundle install
        echo Installing gems with Bundler...
        call bundle install

        :: Install node modules
        echo Next, we're going to install or update Node modules.
        echo You need to have Node.js installed already (https://nodejs.org).
        echo Installing Node modules... This may take a few minutes.
        call npm install

        :: Back to the beginning
        echo Done.
        echo.
        goto begin

:: Don't show these commands to the user
@echo off
:: Keep variables local, and expand at execution time not parse time
setlocal enabledelayedexpansion
:: Set the title of the window
title Electric Book software tests

:: Remember where we are by assigning a variable to the current directory
set location=%~dp0

:: Ask what we're going to be doing.
echo Electric Book tests
echo -------------------
echo.
echo This script tests output to make sure things are working.
echo For instance, use it to compare a previous PDF with a new one.
echo To limit these tests to one output format, include the format
echo as an argument when you run this file, e.g.
echo run-tests print-pdf
echo which will automatically check the default books 'book' and'samples'.
echo To define which book to test, add its folder name as a second argument, e.g.
echo run-tests print-pdf samples
echo.

:: Start and create timestamp
:start

    :: Create a timestamp
    for /f "tokens=2-8 delims=.:/ " %%a in ("%date% %time%") do set timestamp=%%c-%%a-%%bT%%d-%%e-%%f-%%g

:: Check for arguments, so that we can ask:
:: if not defined arguments
:checkForArgs

    if "%~1"=="" set arguments=
    if "%~1"=="print-pdf" (
        if not "%~2"=="" (
        set bookfolderDefined=y
            set "bookfolder=%~2"
        )
        goto printPDF
    )
    if "%~1"=="epub" (
        if not "%~2"=="" (
        set bookfolderDefined=y
            set "bookfolder=%~2"
        )
        goto epub
    )

:: Print-PDF tests
:printPDF

    :: Create a print-pdf with all default settings
    :printPDFDefault

        :: Set default book if it hasn't been defined
        if not defined bookfolder set bookfolder=book

        :: User feedback before starting output script
        echo Running print-PDF default-output tests
        echo and saving log to log-print-pdf-%timestamp%.txt...
        cd ..

        :: Run the output script
        :: User input for print-pdf with defaults would be
        :: "1" for the print-pdf option
        :: "" for the book folder
        :: "" for no subdirectory
        :: "" for no extra configs
        :: "" for no mathjax
        :: n (or anything) to not repeat
        :: which listed as arguments in sequence would be:
        :: run-windows.bat 1 "" "" "" "" n
        :: So we'll use these steps as arguments like this:
        :: printpdf bookfolder subfolder extraconfigs mathjax repeat
        call run-windows printpdf %bookfolder% "" "" "" n >> _tests/log-print-pdf-%timestamp%.txt 2>&1

        :showDiffPDFResult
            start diff-pdf --view "_output/%bookfolder%.pdf" "_tests/print-pdf/%bookfolder%.pdf"

        cd %location%

        :: Tests have run, open log file
        :printPDFDefaultComplete
            echo Print-PDF default-output of %bookfolder% complete. Opening log...
            start log-print-pdf-%timestamp%.txt
            echo.

    :: Output samples book in English with MathJax
    :printPDFSamplesWithMathJax

        :: Make sure we're in the right place
        cd %location%

        :: Don't run this test if a book has been defined
        if "%bookfolderDefined%"=="y" goto printPDFEnd
        echo Running print-PDF tests using Samples with MathJax enabled
        echo and saving log to log-print-pdf-%timestamp%.txt...
        cd ..
        call run-windows printpdf samples "" "" y n >> _tests/log-print-pdf-%timestamp%.txt 2>&1

        :showDiffPDFResult
            start diff-pdf --view _output/samples.pdf _tests/print-pdf/samples.pdf

        cd %location%

        :: Tests have run, open log file
        :printPDFSamplesWithMathJaxComplete
            echo Print-PDF samples output complete. Opening log...
            start log-print-pdf-%timestamp%.txt
            echo.

    :printPDFEnd

    :: If an output format has been defined, then exit now.
    :: Otherwise we'll continue to the next test.
    if defined arguments goto:EOF

:: Epub tests
:epub

        :: Create an epub with all default settings
    :epubDefault

        :: Start in _tests
        cd %location%

        :: Set default book if it hasn't been defined
        if not defined bookfolder set bookfolder=book

        :: User feedback before starting output script
        echo Running epub default-output tests
        echo and saving log to log-epub-%timestamp%.txt...
        cd ..

        :: Run the output script with arguments as:
        :: epub bookfolder subfolder extraconfigs mathjax validation repeat
        call run-windows epub %bookfolder% "" "" "" n n >> _tests/log-epub-%timestamp%.txt 2>&1

        :: Back to _tests
        cd %location%

        :: Set the filename of the epub, sans extension
        :epubSetFilename
            if "%subdirectory%"=="" set epubFileName=%bookfolder%
            if not "%subdirectory%"=="" set epubFileName=%bookfolder%-%subdirectory%

        goto epubValidation

    :: Output samples epub in English with MathJax
    :epubSamplesWithMathJax

        :: Start from _tests
        cd %location%

        :: Don't run this test if a book has been defined
        :: or we've already done this.
        if "%bookfolderDefined%"=="y" goto epubEnd
        if "%epubSamplesWithMathJaxStatus%"=="generated" goto epubEnd
        echo Running epub tests using Samples with MathJax enabled
        echo and saving log to log-epub-%timestamp%.txt...
        cd ..
        call run-windows epub samples "" "" y n n >> %location%/log-epub-%timestamp%.txt 2>&1
        set epubSamplesWithMathJaxStatus=generated

        :: Back to _tests
        cd %location%

        :: Set the filename of the epub, sans extension
        :epubSetFilename
            if "%subdirectory%"=="" set epubFileName=samples
            if not "%subdirectory%"=="" set epubFileName=samples-%subdirectory%

        goto epubValidation

    :: Check if epubcheck is in the PATH, and run it if it is
    :epubValidation

        cd %location%
        echo If EpubCheck is in your PATH, we'll run validation now.

        :: Use a batch-file trick to get the location of epubcheck
        :: https://blogs.msdn.microsoft.com/oldnewthing/20120731-00/?p=7003/
        for /f %%i in ('where epubcheck.jar') do set epubchecklocation=%%i
        if "%epubchecklocation%"=="" echo Couldn't find EpubCheck, sorry.
        if "%epubchecklocation%"=="" goto skipEpubValidation

        :: then run it, saving the error stream to a log file
        :: First, create a timestamp
        for /f "tokens=2-8 delims=.:/ " %%a in ("%date% %time%") do set timestamp=%%c-%%a-%%bT%%d-%%e-%%f-%%g
        set epubCheckLogFile=log-epubcheck-%timestamp%
        echo Found EpubCheck, running validation...
        cd ..\_output
        java -jar %epubchecklocation% %epubFileName%.epub >> %location%/log-epub-%timestamp%.txt 2>&1
        set epubErrorLevel=%errorlevel%
        if "%epubErrorLevel%"=="1" (
            echo Epub not validated, or errors found in %epubFileName%.epub
            )
        if "%epubErrorLevel%"=="0" (
            echo No errors found in %epubFileName%.epub
            )
        echo Opening EpubCheck log...
        echo.
        cd %location%
        start log-epub-%timestamp%.txt

        :skipEpubValidation

        :: Go back to check whether to test Samples, too
        goto epubSamplesWithMathJax

        cd %location%

        :: Tests have run, open log file
        :epubValidationComplete
            echo Epub default-output of %bookfolder% complete. Opening log...
            start log-epub-%timestamp%.txt
            echo.

    :epubEnd

    :: If an output format has been defined, then exit now.
    :: Otherwise we'll continue to the next test.
    if defined arguments (
        echo Tests complete
        goto:EOF
        )

:: To do
:: Use https://github.com/evolvingweb/sitediff to compare
:: GitHub Pages site with local site

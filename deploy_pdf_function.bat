@echo off
echo Desplegant funcio de processament de PDFs...
firebase deploy --only functions:processPdfOnUpload
pause

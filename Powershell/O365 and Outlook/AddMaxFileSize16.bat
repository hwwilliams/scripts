@echo off
REG ADD HKCU\Software\Microsoft\Office\16.0\Outlook\PST /v MaxLargeFileSize /t REG_DWORD /d 2075149312
REG ADD HKCU\Software\Microsoft\Office\16.0\Outlook\PST /v WarnLargeFileSize /t REG_DWORD /d 150368768
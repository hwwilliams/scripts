import os

logPath = "D:\\logarrlogs\\snapraid.log"
logVerify = os.path.isfile(logPath)

if logVerify:
	logSize = os.path.getsize(logPath)
	if logSize >= 1000000:
		os.remove(logPath)
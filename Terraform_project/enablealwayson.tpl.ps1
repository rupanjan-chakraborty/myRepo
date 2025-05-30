Invoke-WebRequest -Uri https://${bucket}.s3.amazonaws.com/${key} -OutFile C:/Temp/enablealwayson.ps1
powershell -ExecutionPolicy Bypass -File C:/Temp/enablealwayson.ps1

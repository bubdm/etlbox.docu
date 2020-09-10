del docs /q /s /f
xcopy .\ETLBoxDocu\_site\* docs /q /s /e /y
git add .
git commit -m "Updating website"
git push
pause
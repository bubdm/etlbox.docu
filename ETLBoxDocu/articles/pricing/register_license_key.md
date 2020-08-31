# Register an ETLBox license key

If you have received a license file (normally name "etlbox.lic") from us, you need to make sure that ETLBox can read this license. 

You have two options here:

### Option 1

Just copy the file in the same folder where the ETLBox.dll resides. This is normally the root folder of your project. 

If you add it to the sources of your project, make sure that the option "Copy to output directory" is set to "Copy always" or "Copy if newer". 

### Option 2

Set up a user-wide or machine-wide environment variable. The name of the Environment variable must be "etlbox" (without quotes).

Copy the conent of your license file into an environment variable called "etlbox". No license file is required then. 

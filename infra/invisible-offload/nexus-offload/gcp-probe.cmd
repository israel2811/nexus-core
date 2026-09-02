@ECHO OFF
SETLOCAL
SET CLOUDSDK_CORE_DISABLE_PROMPTS=1
SET "GCLOUD=C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
IF NOT EXIST "%GCLOUD%" (
  ECHO GCP_SDK=MISSING
  EXIT /B 2
)
ECHO GCP_SDK=FOUND
ECHO ACTIVE_ACCOUNT:
CALL "%GCLOUD%" auth list --filter=status:ACTIVE --format="value(account)" --quiet 2>NUL
ECHO ACTIVE_PROJECT:
CALL "%GCLOUD%" config get-value project --quiet 2>NUL
ECHO BILLING:
FOR /F "usebackq delims=" %%P IN (`CALL "%GCLOUD%" config get-value project --quiet 2^>NUL`) DO SET "PROJECT=%%P"
IF DEFINED PROJECT CALL "%GCLOUD%" billing projects describe "%PROJECT%" --format="value(billingEnabled,billingAccountName)" --quiet 2>NUL
EXIT /B 0

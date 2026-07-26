@echo off
echo A browser will open for Supabase approval.
echo Keep this window open and enter the verification code here.
echo.
npx.cmd --yes supabase@latest login --output-format text --agent no
echo.
if errorlevel 1 (
  echo Supabase login was not completed.
) else (
  echo Supabase login completed successfully.
)
pause

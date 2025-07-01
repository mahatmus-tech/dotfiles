@echo off
echo ============================================
echo          Otimizacao do Windows
echo ============================================

echo Executando CHKDSK...
echo S | chkdsk C: /f /r
echo CHKDSK finalizado.
echo.

echo Executando SFC (System File Checker)...
sfc /scannow
echo SFC finalizado.
echo.

echo Executando DISM (Deployment Image Servicing and Management)...
DISM /Online /Cleanup-Image /RestoreHealth
echo DISM finalizado.
echo.

echo Desativando Hibernacao com Powercfg...
powercfg /h off
echo Hibernacao desativada.
echo.

echo Limpando disco com Cleanmgr...
cleanmgr /sagerun:1
echo Limpeza de disco finalizada.
echo.

echo ============================================
echo          Otimizacao Concluida
echo ============================================

echo The system will restart in 10 seconds to run CHKDSK.
echo Press Ctrl+C to cancel shutdown.
shutdown /r /t 10 /c "Restarting to complete disk checks..."

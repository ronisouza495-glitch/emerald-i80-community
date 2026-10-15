@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Emerald i80 - Instalador e inicializador portatil

set "APP_VERSION=1.1.0"
set "RELEASE_TAG=v1.1.0"
if not defined EMERALD_RELEASE_BASE set "EMERALD_RELEASE_BASE=https://github.com/ronisouza495-glitch/emerald-i80-community/releases/download/%RELEASE_TAG%"
set "PAYLOAD_NAME=emerald-i80-runtime-%RELEASE_TAG%.zip"
set "PAYLOAD_URL=%EMERALD_RELEASE_BASE%/%PAYLOAD_NAME%"
set "PAYLOAD_SHA256=6c6576bb1c6fc878842555e73b4c95de0fa3fd5900871398e6725270b84d9390"
set "SERVER_PACKAGE_NAME=Emerald-i80-Servidor-v1.1.0.tar.gz"
set "SERVER_PACKAGE_URL=%EMERALD_RELEASE_BASE%/%SERVER_PACKAGE_NAME%"
set "SERVER_PACKAGE_SHA256=405d988d14bb5a07c7b27ff5d09db5f7d3af30ab7496b1a0b15f882936ae8f17"
if not defined EMERALD_INSTALL_ROOT if exist "D:\" set "EMERALD_INSTALL_ROOT=D:\EmeraldI80"
if not defined EMERALD_INSTALL_ROOT set "EMERALD_INSTALL_ROOT=%LOCALAPPDATA%\EmeraldI80"
set "INSTALL_ROOT=%EMERALD_INSTALL_ROOT%"
set "RUNTIME_DIR=%INSTALL_ROOT%\runtime"
set "SERVER_DIR=%INSTALL_ROOT%\server"
set "DOWNLOAD_DIR=%INSTALL_ROOT%\downloads"
set "STATE_DIR=%INSTALL_ROOT%\state"
set "LOG_DIR=%INSTALL_ROOT%\logs"
set "SECRETS_FILE=%STATE_DIR%\local-secrets.cmd"
set "INSTALL_MARKER=%STATE_DIR%\server-installed-%APP_VERSION%.txt"
set "PAYLOAD_MARKER=%STATE_DIR%\payload-%APP_VERSION%.txt"

echo ============================================================
echo       Emerald i80 - instalador e inicializador seguro
echo ============================================================
echo Instalacao persistente: %INSTALL_ROOT%
echo.

for %%D in ("%INSTALL_ROOT%" "%DOWNLOAD_DIR%" "%STATE_DIR%" "%LOG_DIR%") do if not exist "%%~D" mkdir "%%~D"

call :ensure_payload
if errorlevel 1 goto :failed

if not exist "%INSTALL_MARKER%" (
  call :download_server_package
  if errorlevel 1 goto :failed
  call :initialize_database
  if errorlevel 1 goto :failed
)

call :start_stack
if errorlevel 1 goto :failed
call :offer_account
if errorlevel 1 echo [AVISO] A conta nao foi criada, mas o servidor continua ativo.

echo.
echo [OK] Emerald i80 foi iniciado.
echo MySQL: somente local, porta 3306
echo AuthServer: porta 3724
echo WorldServer: porta 8085
echo.
echo Nas proximas execucoes, este BAT reutilizara a instalacao local.
pause
exit /b 0

:ensure_payload
if exist "%PAYLOAD_MARKER%" if exist "%RUNTIME_DIR%\runtime-manifest.txt" (
  set /p "CURRENT_SHA=" < "%PAYLOAD_MARKER%"
  call :compare_payload_marker
  if not errorlevel 1 (
    echo [OK] Runtime %APP_VERSION% ja instalado; nenhum download necessario.
    exit /b 0
  )
)

echo [1/4] Baixando runtime assinado por hash...
set "PAYLOAD_FILE=%DOWNLOAD_DIR%\%PAYLOAD_NAME%"
if exist "%PAYLOAD_FILE%" del /q "%PAYLOAD_FILE%"

where curl.exe >nul 2>&1
if not errorlevel 1 (
  curl.exe --fail --location --retry 3 --connect-timeout 20 --output "%PAYLOAD_FILE%" "%PAYLOAD_URL%"
) else (
  powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri $env:PAYLOAD_URL -OutFile $env:PAYLOAD_FILE"
)
if errorlevel 1 (
  echo [ERRO] Falha no download: %PAYLOAD_URL%
  exit /b 10
)

for /f "usebackq delims=" %%H in (`powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$s=[Security.Cryptography.SHA256]::Create(); try{([BitConverter]::ToString($s.ComputeHash([IO.File]::ReadAllBytes($env:PAYLOAD_FILE)))).Replace('-','').ToLowerInvariant()}finally{$s.Dispose()}"`) do set "DOWNLOADED_SHA=%%H"
if /I not "%DOWNLOADED_SHA%"=="%PAYLOAD_SHA256%" (
  echo [ERRO] O pacote baixado nao passou na verificacao SHA-256.
  echo Esperado: %PAYLOAD_SHA256%
  echo Recebido: %DOWNLOADED_SHA%
  del /q "%PAYLOAD_FILE%" >nul 2>&1
  exit /b 11
)

echo [2/4] Extraindo runtime verificado...
if exist "%RUNTIME_DIR%" rmdir /s /q "%RUNTIME_DIR%"
mkdir "%RUNTIME_DIR%"
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -LiteralPath $env:PAYLOAD_FILE -DestinationPath $env:RUNTIME_DIR -Force"
if errorlevel 1 exit /b 12
if not exist "%RUNTIME_DIR%\runtime-manifest.txt" (
  echo [ERRO] Pacote incompleto: runtime-manifest.txt ausente.
  exit /b 13
)
>"%PAYLOAD_MARKER%" echo %PAYLOAD_SHA256%
echo [OK] Runtime verificado e instalado.
exit /b 0

:compare_payload_marker
if /I "%CURRENT_SHA%"=="%PAYLOAD_SHA256%" exit /b 0
exit /b 1

:download_server_package
echo.
echo [3/4] Baixando o servidor completo. Isso pode demorar...
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$destination=$env:INSTALL_ROOT; $root=[IO.Path]::GetPathRoot([IO.Path]::GetFullPath($destination)); $free=([IO.DriveInfo]::new($root)).AvailableFreeSpace; $needed=6GB; Write-Host ('Necessario: {0:N2} GiB; livre: {1:N2} GiB' -f ($needed/1GB),($free/1GB)); if($free -lt $needed){exit 2}"
if errorlevel 1 (
  echo [ERRO] Sao necessarios pelo menos 6 GiB livres para baixar e instalar.
  echo Libere espaco ou defina EMERALD_INSTALL_ROOT em outra unidade.
  exit /b 26
)
if exist "%SERVER_DIR%" (
  echo [ERRO] Ja existe uma instalacao parcial em %SERVER_DIR%.
  echo Renomeie-a para preservar os dados e execute novamente.
  exit /b 21
)
set "SERVER_PACKAGE_FILE=%DOWNLOAD_DIR%\%SERVER_PACKAGE_NAME%"
if exist "%SERVER_PACKAGE_FILE%" del /q "%SERVER_PACKAGE_FILE%"
where curl.exe >nul 2>&1
if not errorlevel 1 (
  curl.exe --fail --location --retry 3 --connect-timeout 20 --output "%SERVER_PACKAGE_FILE%" "%SERVER_PACKAGE_URL%"
) else (
  powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri $env:SERVER_PACKAGE_URL -OutFile $env:SERVER_PACKAGE_FILE"
)
if errorlevel 1 exit /b 22
for /f "usebackq delims=" %%H in (`powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$s=[Security.Cryptography.SHA256]::Create(); try{([BitConverter]::ToString($s.ComputeHash([IO.File]::ReadAllBytes($env:SERVER_PACKAGE_FILE)))).Replace('-','').ToLowerInvariant()}finally{$s.Dispose()}"`) do set "SERVER_DOWNLOADED_SHA=%%H"
if /I not "%SERVER_DOWNLOADED_SHA%"=="%SERVER_PACKAGE_SHA256%" (
  echo [ERRO] O servidor baixado nao passou na verificacao SHA-256.
  del /q "%SERVER_PACKAGE_FILE%" >nul 2>&1
  exit /b 23
)
mkdir "%SERVER_DIR%"
tar.exe -xzf "%SERVER_PACKAGE_FILE%" -C "%SERVER_DIR%" --strip-components 1
if errorlevel 1 exit /b 24
for %%F in ("worldserver.exe" "authserver.exe" "_Server\mysql\bin\mysqld.exe" "BANCO_LIMPO\05_web_estrutura.sql" "Data\dbc") do if not exist "%SERVER_DIR%\%%~F" exit /b 25
if not exist "%SERVER_DIR%\Logs" mkdir "%SERVER_DIR%\Logs"

call :generate_local_secret
if errorlevel 1 exit /b 27
call "%SECRETS_FILE%"

powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$files=@('%SERVER_DIR%\authserver.conf','%SERVER_DIR%\worldserver.conf'); foreach($f in $files){$c=[IO.File]::ReadAllText($f).Replace('__EMERALD_DB_PASSWORD__','%DB_PASSWORD%'); [IO.File]::WriteAllText($f,$c,[Text.UTF8Encoding]::new($false))}"
if errorlevel 1 exit /b 28

echo [OK] Servidor verificado e extraido sem contas ou personagens privados.
exit /b 0

:generate_local_secret
for /f "usebackq delims=" %%S in (`powershell.exe -NoLogo -NoProfile -NonInteractive -Command "-join ((1..32) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })"`) do set "NEW_SECRET=%%S"
if not defined NEW_SECRET exit /b 1
>"%SECRETS_FILE%" echo @set "DB_PASSWORD=%NEW_SECRET%"
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$p=$env:SECRETS_FILE; $acl=Get-Acl -LiteralPath $p; $acl.SetAccessRuleProtection($true,$false); $rule=New-Object Security.AccessControl.FileSystemAccessRule($env:USERNAME,'FullControl','Allow'); $acl.SetAccessRule($rule); Set-Acl -LiteralPath $p -AclObject $acl" >nul 2>&1
set "NEW_SECRET="
exit /b 0

:initialize_database
echo.
echo [4/4] Criando banco limpo (sem contas e personagens privados)...
set "MYSQL_EXE=%SERVER_DIR%\_Server\mysql\bin\mysql.exe"
set "MYSQLD_EXE=%SERVER_DIR%\_Server\mysql\bin\mysqld.exe"
set "MYSQL_CNF=%SERVER_DIR%\_Server\mysql\bin\my.cnf"
if not exist "%SERVER_DIR%\_Server\mysql\data\mysql" (
  robocopy "%SERVER_DIR%\MYSQL_DATA_BASE" "%SERVER_DIR%\_Server\mysql\data" /E /COPY:DAT /DCOPY:DAT /R:2 /W:2 /NP /NFL /NDL /NJH /NJS
  if errorlevel 8 exit /b 30
)

call :port_3306_free_or_ours blank
if errorlevel 1 exit /b 31
call :start_mysql
if errorlevel 1 exit /b 32
  call :wait_mysql_initial
if errorlevel 1 exit /b 33

"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent < "%SERVER_DIR%\BANCO_LIMPO\01_auth_estrutura.sql"
if errorlevel 1 exit /b 34
if exist "%SERVER_DIR%\BANCO_LIMPO\02_auth_realmlist.sql" "%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent auth < "%SERVER_DIR%\BANCO_LIMPO\02_auth_realmlist.sql"
if errorlevel 1 exit /b 35
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent < "%SERVER_DIR%\BANCO_LIMPO\03_characters_estrutura.sql"
if errorlevel 1 exit /b 36
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent < "%SERVER_DIR%\BANCO_LIMPO\04_world_completo.sql"
if errorlevel 1 exit /b 37
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent --execute="CREATE DATABASE IF NOT EXISTS web DEFAULT CHARACTER SET utf8;"
if errorlevel 1 exit /b 38
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent web < "%SERVER_DIR%\BANCO_LIMPO\05_web_estrutura.sql"
if errorlevel 1 exit /b 39

call "%SECRETS_FILE%"
set "SECURE_SQL=DELETE FROM mysql.user WHERE User=''; CREATE USER 'emerald'@'127.0.0.1' IDENTIFIED BY '%DB_PASSWORD%'; GRANT ALL PRIVILEGES ON auth.* TO 'emerald'@'127.0.0.1'; GRANT ALL PRIVILEGES ON characters.* TO 'emerald'@'127.0.0.1'; GRANT ALL PRIVILEGES ON world.* TO 'emerald'@'127.0.0.1'; GRANT ALL PRIVILEGES ON web.* TO 'emerald'@'127.0.0.1'; UPDATE auth.realmlist SET address='127.0.0.1', localAddress='127.0.0.1', localSubnetMask='255.255.255.0', port=8085 WHERE id=1; SET PASSWORD FOR 'root'@'localhost'=PASSWORD('%DB_PASSWORD%'); FLUSH PRIVILEGES;"
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent --execute="%SECURE_SQL%"
if errorlevel 1 exit /b 38
set "SECURE_SQL="

>"%INSTALL_MARKER%" echo version=%APP_VERSION%
>>"%INSTALL_MARKER%" echo installed=%DATE% %TIME%
echo [OK] Banco limpo criado; nenhuma conta padrao foi adicionada.
exit /b 0

:start_stack
call "%SECRETS_FILE%"
set "MYSQL_EXE=%SERVER_DIR%\_Server\mysql\bin\mysql.exe"
set "MYSQLD_EXE=%SERVER_DIR%\_Server\mysql\bin\mysqld.exe"
set "MYSQL_CNF=%SERVER_DIR%\_Server\mysql\bin\my.cnf"
call :mysql_authenticated
if errorlevel 1 (
  call :port_3306_free_or_ours secured
  if errorlevel 1 exit /b 40
  call :start_mysql
  if errorlevel 1 exit /b 41
  call :wait_mysql_secured
  if errorlevel 1 exit /b 42
)
echo [OK] MySQL respondeu na porta e autenticou corretamente.

call :process_for_install authserver.exe
if errorlevel 1 start "Emerald AuthServer" /D "%SERVER_DIR%" "%SERVER_DIR%\authserver.exe"
timeout /t 4 /nobreak >nul
call :process_for_install authserver.exe
if errorlevel 1 (
  echo [ERRO] AuthServer encerrou durante a inicializacao. Consulte %SERVER_DIR%\Logs.
  exit /b 43
)
echo [OK] AuthServer em execucao.

call :process_for_install worldserver.exe
if errorlevel 1 start "Emerald WorldServer" /D "%SERVER_DIR%" "%SERVER_DIR%\worldserver.exe"
timeout /t 8 /nobreak >nul
call :process_for_install worldserver.exe
if errorlevel 1 (
  echo [ERRO] WorldServer encerrou durante a inicializacao. Consulte %SERVER_DIR%\Logs.
  exit /b 44
)
echo [OK] WorldServer em execucao.
exit /b 0

:start_mysql
pushd "%SERVER_DIR%\_Server"
start "Emerald MySQL" /min "%MYSQLD_EXE%" --defaults-file="%MYSQL_CNF%" --standalone --console
popd
exit /b 0

:wait_mysql_initial
for /l %%N in (1,1,60) do (
  "%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --password=ascent --execute="SELECT 1" >nul 2>&1 && exit /b 0
  timeout /t 1 /nobreak >nul
)
echo [ERRO] MySQL nao aceitou a autenticacao inicial em 60 segundos.
exit /b 1

:wait_mysql_secured
for /l %%N in (1,1,60) do (
  call :mysql_authenticated
  if not errorlevel 1 exit /b 0
  timeout /t 1 /nobreak >nul
)
echo [ERRO] MySQL nao autenticou em 60 segundos.
exit /b 1

:mysql_authenticated
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=emerald --password=%DB_PASSWORD% --execute="SELECT 1" >nul 2>&1
exit /b %ERRORLEVEL%

:port_3306_free_or_ours
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "if(Get-NetTCPConnection -State Listen -LocalPort 3306 -ErrorAction SilentlyContinue){exit 1}else{exit 0}" >nul 2>&1
if not errorlevel 1 exit /b 0
if /I "%~1"=="secured" (
  call :mysql_authenticated
  if not errorlevel 1 exit /b 0
)
echo [ERRO] A porta 3306 esta ocupada por outro processo ou banco.
echo Feche o outro MySQL para evitar conectar ao banco errado.
exit /b 1

:process_for_install
powershell.exe -NoLogo -NoProfile -NonInteractive -Command "$n='%~1'; $root=$env:SERVER_DIR; $p=Get-CimInstance Win32_Process -Filter ('Name='''+$n+'''') -ErrorAction SilentlyContinue | Where-Object {$_.ExecutablePath -and $_.ExecutablePath.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)}; if($p){exit 0}else{exit 1}" >nul 2>&1
exit /b %ERRORLEVEL%

:offer_account
echo.
set "CREATE_ACCOUNT="
set /p "CREATE_ACCOUNT=Deseja criar uma conta agora? [S/N]: "
if /I not "%CREATE_ACCOUNT%"=="S" exit /b 0
set "ACCOUNT_NAME="
set "ACCOUNT_PASSWORD="
set /p "ACCOUNT_NAME=Nome da conta (letras, numeros e _): "
set /p "ACCOUNT_PASSWORD=Senha da conta (letras, numeros e _): "
echo(%ACCOUNT_NAME%|findstr /R /C:"^[A-Za-z0-9_][A-Za-z0-9_]*$" >nul || exit /b 1
echo(%ACCOUNT_PASSWORD%|findstr /R /C:"^[A-Za-z0-9_][A-Za-z0-9_]*$" >nul || exit /b 1
call "%SECRETS_FILE%"
set "ACCOUNT_SQL=SET @u=UPPER('%ACCOUNT_NAME%'); SET @p=UPPER('%ACCOUNT_PASSWORD%'); INSERT INTO auth.account(username,sha_pass_hash,expansion,locked) SELECT @u,SHA1(CONCAT(@u,':',@p)),2,0 FROM DUAL WHERE NOT EXISTS(SELECT 1 FROM auth.account WHERE username=@u); SET @aid=(SELECT id FROM auth.account WHERE username=@u LIMIT 1); INSERT IGNORE INTO auth.realmcharacters(realmid,acctid,numchars) SELECT id,@aid,0 FROM auth.realmlist;"
"%MYSQL_EXE%" --protocol=tcp --host=127.0.0.1 --port=3306 --user=emerald --password=%DB_PASSWORD% --execute="%ACCOUNT_SQL%"
if errorlevel 1 exit /b 1
set "ACCOUNT_PASSWORD="
set "ACCOUNT_SQL="
echo [OK] Conta %ACCOUNT_NAME% criada ou ja existente. Expansao: WotLK.
exit /b 0

:failed
set "EXIT_CODE=%ERRORLEVEL%"
echo.
echo [FALHA] A operacao foi interrompida com codigo %EXIT_CODE%.
echo A pasta original do repack nao foi alterada nem excluida.
echo Instalacao local: %INSTALL_ROOT%
pause
exit /b %EXIT_CODE%

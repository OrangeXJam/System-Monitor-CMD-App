@echo off
SET SCRIPT_NAME=SM.sh
SET DOCKER_IMAGE_NAME=system-monitor:v1
SET LOG_DIR_NAME=monitor_logs

powershell -Command "if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Write-Host 'Docker is required for the program to run.' -ForegroundColor Red; Write-Host 'Please install Docker from their official site:' -ForegroundColor Red; Write-Host 'https://docs.docker.com/desktop/' -ForegroundColor Red; exit 1 }"
IF ERRORLEVEL 1 GOTO :EOF

IF NOT EXIST %LOG_DIR_NAME% (
    MKDIR %LOG_DIR_NAME%
    ECHO Created local log directory: %LOG_DIR_NAME%
)

ECHO Checking for image: %DOCKER_IMAGE_NAME%...
docker image inspect %DOCKER_IMAGE_NAME% >NUL 2>&1
IF ERRORLEVEL 1 GOTO BUILD_IMAGE_BLOCK

GOTO RUN_CONTAINER_BLOCK

:BUILD_IMAGE_BLOCK
ECHO Image not found. Building Docker Image: %DOCKER_IMAGE_NAME%...
docker build -t %DOCKER_IMAGE_NAME% .
IF ERRORLEVEL 1 GOTO ERROR_BUILD
GOTO RUN_CONTAINER_BLOCK

:RUN_CONTAINER_BLOCK
ECHO Running Container; Logs will be saved to: "%CD%\%LOG_DIR_NAME%"
docker run -it --rm ^
    --privileged ^
    --gpus all ^
    --gpus all ^
    --name my_system_monitor ^
    --pid=host ^
    --net=host ^
    --cap-add=ALL ^
    -v /dev:/dev ^
    -v "%CD%\%LOG_DIR_NAME%":/app ^
    %DOCKER_IMAGE_NAME%
GOTO :EOF

:ERROR_BUILD
ECHO Error: Docker image build failed.
PAUSE

:EOF
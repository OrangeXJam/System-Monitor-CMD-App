# CMD System Monitor

A simple app to show the components of your machine and their metrics status.

---

## Installation & Requirements

**Requirements:** Docker

### Windows
- Open Docker.
- Go to the `System-Monitor-Windows-Linux` folder.
- Run the `run_app.bat` file.

### Linux
- Open a terminal.
- Go to the `System-Monitor-Windows-Linux` folder.
- Run `run_app.sh`.
- This will install the required libraries and run the app automatically.

### macOS
- Open Docker.
- Open a terminal.
- Go to the `System-Monitor-MAC` folder.
- Run `run_app.sh`.

---

## Report Generation
- A local HTML file is included for report generation.
- It can be used to visualize metrics from previously logged data.

---

## Important Notices

- The only fully working version currently is the **Linux native version**.
- A **native Linux installation** is required (virtual machines will not work).
- The Windows and macOS versions may show missing data values due to restrictions when running inside virtual containers.
- This may be fixed in a future release if the project is updated.

---

## Privacy Notices

- The application continuously logs system metrics while it is running.
- Logged data is stored locally at: "monitor_logs/system_monitor_log.log"
- Logging starts automatically when the application is opened.
- Logging stops automatically when the application is closed.
- No data is transmitted externally; all logs remain on the local machine.

### Disabling Logging (Optional)

If you do **not** want logging to happen:

#### Windows
- Open the `SM_VE` file.
- Remove or comment out the following lines at the bottom of the file:

```bash
log_data &
logger_pid=$!

🛠️ JaCaL's Calibration Wizard: Install Guide
This wizard is a 21-step journey to turn your 3D printer into a precision machine. It handles everything from hardware checks to final plastic tuning.

How to Install
Open Putty or your favorite terminal and log into your printer (usually pi@mainsail.local).

Paste this command and hit Enter:

Bash
git clone https://github.com/ItsJaCaL/Calibration_Hub.git && cd Calibration_Hub && chmod +x install.sh && ./install.sh
Wait for the green 🚀 INSTALLATION COMPLETE message. It will give you a link like http://192.168.50.254:3258.

How to Use
Open the Link: Copy the link from the terminal and paste it into your web browser (Chrome or Edge work best).

Follow the Steps: Start at Step 0. The Wizard will guide you.

The Emergency Button: There is a big red button at the top. If the printer makes a scary noise or tries to eat itself, HIT IT IMMEDIATELY.

Save as You Go: Some steps will ask you to click "Save Config." The printer will restart, but the Wizard will stay on the same page for you.

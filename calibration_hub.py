# calibration_hub.py - 3D Royal Lab Master Backend

class CalibrationHub:
    def __init__(self, config):
        self.printer = config.get_printer()
        
    def get_status(self, eventtime):
        # Safely pull the raw config dictionary from memory
        try:
            raw_config = self.printer.lookup_object('configfile').get_status(0)['config']
        except Exception:
            raw_config = {}

        steppers = []
        for section in raw_config.keys():
            if 'stepper_' in section:
                # Extracts 'x1' from '[tmc5160 stepper_x1]'
                name = section.split()[-1].replace('stepper_', '')
                if name not in steppers:
                    steppers.append(name)
        
        if 'extruder' in raw_config and 'extruder' not in steppers:
            steppers.append('extruder')
            
        # Klipper automatically exposes this to Moonraker
        return {
            "motors": steppers,
            "has_z_tilt": "z_tilt" in raw_config,
            "has_bltouch": "bltouch" in raw_config,
            "has_probe": "probe" in raw_config,
            "has_bed_pid": "heater_bed" in raw_config
        }

def load_config(config):
    return CalibrationHub(config)
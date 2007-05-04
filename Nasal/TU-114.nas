autotakeoff = func {
  ato_start();      # Initiation stuff.
  ato_mode();       # Take-off/Climb-out mode handler.
  ato_spddep();     # Speed dependent actions.

  # Re-schedule the next loop if the Take-Off function is enabled.
  if(getprop("/autopilot/locks/auto-take-off") != "Enabled") {
#    print("Auto Take-Off disabled");
  } else {
    settimer(autotakeoff, 0.5);
  }
}
#--------------------------------------------------------------------
ato_start = func {
  # This script checks that the ground-roll-heading has been reset
  # (< -999) and that the a/c is on the ground.
  if(getprop("/autopilot/settings/ground-roll-heading-deg") < -999) {
    if(getprop("/position/altitude-agl-ft") < 0.01) {
      hdgdeg = getprop("/orientation/heading-deg");
      topp =   getprop("/autopilot/settings/take-off-prop-pitch");
      toflp =  getprop("/autopilot/settings/take-off-flap");
      togrpd = getprop("/autopilot/settings/take-off-ground-roll-pitch-deg");
      setprop("/controls/engines/engine[0]/propeller-pitch", topp);
      setprop("/controls/engines/engine[1]/propeller-pitch", topp);
      setprop("/controls/engines/engine[2]/propeller-pitch", topp);
      setprop("/controls/engines/engine[3]/propeller-pitch", topp);
      setprop("/controls/flight/flaps", toflp);
      setprop("/autopilot/settings/ground-roll-heading-deg", hdgdeg);
      setprop("/autopilot/settings/true-heading-deg", hdgdeg);
      setprop("/autopilot/internal/target-pitch-deg", togrpd);
      setprop("/autopilot/settings/target-speed-kt", 320);
      setprop("/autopilot/locks/altitude", "take-off");
      setprop("/autopilot/locks/speed", "speed-with-throttle");
      setprop("/autopilot/locks/heading", "wing-leveler");
      setprop("/autopilot/locks/rudder-control", "rudder-hold");
    }
  }
}
#--------------------------------------------------------------------
ato_mode = func {
  # This script sets the auto-takeoff mode and handles the switch
  # to climb-out mode.
  mode =     getprop("/autopilot/locks/altitude");
  agl =      getprop("/position/altitude-agl-ft");
  airspeed = getprop("/velocities/airspeed-kt");
  rotspeed = getprop("/autopilot/settings/take-off-rotation-speed-kts");
  rotdeg =   getprop("/autopilot/settings/take-off-rotation-deg");
  if(mode == "take-off") {
    if(airspeed > rotspeed) {
      interpolate("/autopilot/internal/target-pitch-deg", rotdeg, 4);
    }
  }
  coalt = getprop("/autopilot/settings/climb-out-altitude-ft");
  if(agl > coalt) {
    copd = getprop("/autopilot/settings/climb-out-pitch-deg");
    setprop("/autopilot/internal/target-pitch-deg", copd);
    setprop("/autopilot/locks/altitude", "climb-out");
    setprop("/controls/gear/gear-down", "false");
    setprop("/autopilot/locks/rudder-control", "reset");
    interpolate("/controls/flight/rudder", 0, 10);
  } else {
    setprop("/autopilot/locks/altitude", "take-off");
  }
}
#--------------------------------------------------------------------
ato_spddep = func {
  # This script controls speed dependent actions.
  airspeed = getprop("/velocities/airspeed-kt");
  if(airspeed < 155) {
#    Do nothing
  } else {
    if(airspeed < 175) {
      setprop("/controls/flight/flaps", 0.32);
    } else {
      if(airspeed < 180) {
        setprop("/controls/flight/flaps", 0.16);
      } else {
        if(airspeed < 190) {
          setprop("/controls/flight/flaps", 0.08);
        } else {
          if(airspeed < 195) {
            setprop("/controls/flight/flaps", 0.0);
          } else {
            if(airspeed < 196) {
              setprop("/controls/flight/flaps", 0.0);
            } else {
              crpp = getprop("/autopilot/settings/cruise-prop-pitch");
              setprop("/autopilot/locks/heading", "true-heading-hold");
              setprop("/autopilot/locks/speed", "mach-with-throttle");
              setprop("/autopilot/locks/altitude", "mach-climb");
              setprop("/autopilot/locks/auto-take-off", "Disabled");
              setprop("/controls/engines/engine[0]/propeller-pitch", crpp);
              setprop("/controls/engines/engine[1]/propeller-pitch", crpp);
              setprop("/controls/engines/engine[2]/propeller-pitch", crpp);
              setprop("/controls/engines/engine[3]/propeller-pitch", crpp);
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
autoland = func {
  agl = getprop("/position/altitude-agl-ft");
  hdgdeg = getprop("/orientation/heading-deg");
  
  if(agl > 200) {
    # Glide Slope phase.
    atl_heading();
    atl_spddep();
    
  } else {
    # Touch Down phase.
    atl_touchdown();
  }

  # Re-schedule the next loop if the Landing function is enabled.
  if(getprop("/autopilot/locks/auto-landing") != "Enabled") {
  } else {
    settimer(autoland, 0.5);
  }
}
#--------------------------------------------------------------------
atl_spddep = func {
  # This script handles speed related actions.
  if(getprop("/autopilot/locks/speed") != "speed-with-throttle") {
    setprop("/autopilot/locks/speed", "speed-with-throttle");
  }
  if(getprop("/autopilot/settings/target-speed-kt") > 235) {
    interpolate("/autopilot/settings/target-speed-kt", 235, 20);
  }
  airspeed = getprop("/velocities/airspeed-kt");
  if(airspeed < 170) {
      setprop("/autopilot/locks/AoA-lock", "Engaged");
      setprop("/controls/flight/flaps", 1.0);
      interpolate("/controls/engines/engine[0]/propeller-pitch", 0.9, 10);
      interpolate("/controls/engines/engine[1]/propeller-pitch", 0.9, 10);
      interpolate("/controls/engines/engine[2]/propeller-pitch", 0.9, 10);
      interpolate("/controls/engines/engine[3]/propeller-pitch", 0.9, 10);
  } else {
    if(airspeed < 180) {
      setprop("/autopilot/settings/target-speed-kt", 165);
      setprop("/controls/flight/flaps", 0.82);
      setprop("/controls/gear/gear-down", "true");
    } else {
      if(airspeed < 190) {
        setprop("/autopilot/settings/target-speed-kt", 175);
        setprop("/controls/flight/flaps", 0.64);
      } else {
        if(airspeed < 200) {
          setprop("/autopilot/settings/target-speed-kt", 185);
          setprop("/controls/flight/flaps", 0.48);
        } else {
          if(airspeed < 210) {
            setprop("/autopilot/settings/target-speed-kt", 195);
            setprop("/controls/flight/flaps", 0.32);
          } else {
            if(airspeed < 220) {
              setprop("/autopilot/settings/target-speed-kt", 205);
              setprop("/controls/flight/flaps", 0.16);
            } else {
              if(airspeed < 230) {
                setprop("/autopilot/settings/target-speed-kt", 215);
                setprop("/controls/flight/flaps", 0.08);
              } else {
                if(airspeed < 240) {
                  setprop("/autopilot/settings/target-speed-kt", 225);
                  if(getprop("/autopilot/internal/clamped-gs-rate-of-climb") != 0) {
                    setprop("/autopilot/internal/clamped-gs-rate-of-climb", 0);
                  }
                  setprop("/autopilot/locks/altitude", "gs1-hold");
                }
              }
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
atl_touchdown = func {
  # Touch Down phase.
  agl = getprop("/position/altitude-agl-ft");
  vfps = getprop("/velocities/vertical-speed-fps");
  setprop("/autopilot/settings/target-vfps", vfps);
  setprop("/autopilot/locks/AoA-lock", "Off");
  setprop("/autopilot/locks/heading", "");

  if(agl < 0.01) {
    # Brakes on, Rudder heading hold on & disable IL mode.
    setprop("/controls/gear/brake-left", 0.04);
    setprop("/controls/gear/brake-right", 0.04);
    setprop("/autopilot/settings/ground-roll-heading-deg", -999.9);
    setprop("/autopilot/locks/auto-landing", "Disabled");
    setprop("/autopilot/locks/auto-take-off", "Enabled");
    setprop("/autopilot/locks/altitude", "Off");
    setprop("/autopilot/settings/target-vfps", 0);
    setprop("/autopilot/settings/take-off-pitch-deg", 0);
    interpolate("/controls/flight/elevator-trim", 0, 10.0);
  }
  if(agl < 1) {
    setprop("/autopilot/settings/target-vfps", -0.1);
  } else {
    if(agl < 2) {
      setprop("/autopilot/settings/target-vfps", -0.5);
    } else {
      if(agl < 4) {
        setprop("/autopilot/settings/target-vfps", -1);
          setprop("/autopilot/locks/AoA-lock", "Off");
          setprop("/autopilot/locks/speed", "Off");
          setprop("/controls/engines/engine[0]/throttle", 0);
          setprop("/controls/engines/engine[1]/throttle", 0);
          setprop("/controls/engines/engine[2]/throttle", 0);
          setprop("/controls/engines/engine[3]/throttle", 0);
      } else {
        if(agl < 8) {
          setprop("/autopilot/settings/target-vfps", -2);
        } else {
          if(agl < 16) {
            setprop("/autopilot/settings/target-vfps", -4);
          } else {
            if(agl < 20) {
              setprop("/autopilot/settings/target-vfps", -6);
            } else {
              if(agl < 40) {
                setprop("/autopilot/settings/target-vfps", -8);
              } else {
                if(agl < 80) {
                  setprop("/autopilot/settings/target-vfps", -10);
                } else {
                  setprop("/autopilot/settings/target-vfps", -12);
                  setprop("/autopilot/locks/altitude", "vfps-hold-ls");
                }
              }
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
atl_heading = func {
  # This script handles heading dependent actions.
  hdnddf =  getprop("/instrumentation/nav[0]/heading-needle-deflection");
  aspd =    getprop("/velocities/airspeed-kt");
  nvfaspd = getprop("/autopilot/settings/nav1-final-approach-speed-kt");
  if(aspd > nvfaspd) {
    setprop("/autopilot/locks/heading", "nav1-hold");
  } else {
    if(hdnddf < 3) {
      if(hdnddf > -3) {
        setprop("/autopilot/locks/heading", "nav1-hold-fa");
      }
    }
  }
}
#--------------------------------------------------------------------
auto_prop_pitch = func {
  mach = getprop("/velocities/mach");
  
  if(mach < 0.25) {
    setprop("/controls/engines/engine[0]/propeller-pitch", 1.0);
    setprop("/controls/engines/engine[1]/propeller-pitch", 1.0);
    setprop("/controls/engines/engine[2]/propeller-pitch", 1.0);
    setprop("/controls/engines/engine[3]/propeller-pitch", 1.0);
  } else {
    if(mach < 0.26) {
      setprop("/controls/engines/engine[0]/propeller-pitch", 0.95);
      setprop("/controls/engines/engine[1]/propeller-pitch", 0.95);
      setprop("/controls/engines/engine[2]/propeller-pitch", 0.95);
      setprop("/controls/engines/engine[3]/propeller-pitch", 0.95);
    } else {
      if(mach < 0.27) {
        setprop("/controls/engines/engine[0]/propeller-pitch", 0.9);
        setprop("/controls/engines/engine[1]/propeller-pitch", 0.9);
        setprop("/controls/engines/engine[2]/propeller-pitch", 0.9);
        setprop("/controls/engines/engine[3]/propeller-pitch", 0.9);
      } else {
        if(mach < 0.28) {
          setprop("/controls/engines/engine[0]/propeller-pitch", 0.85);
          setprop("/controls/engines/engine[1]/propeller-pitch", 0.85);
          setprop("/controls/engines/engine[2]/propeller-pitch", 0.85);
          setprop("/controls/engines/engine[3]/propeller-pitch", 0.85);
        } else {
          if(mach < 0.29) {
            setprop("/controls/engines/engine[0]/propeller-pitch", 0.8);
            setprop("/controls/engines/engine[1]/propeller-pitch", 0.8);
            setprop("/controls/engines/engine[2]/propeller-pitch", 0.8);
            setprop("/controls/engines/engine[3]/propeller-pitch", 0.8);
          } else {
            if(mach < 0.3) {
              setprop("/controls/engines/engine[0]/propeller-pitch", 0.7);
              setprop("/controls/engines/engine[1]/propeller-pitch", 0.7);
              setprop("/controls/engines/engine[2]/propeller-pitch", 0.7);
              setprop("/controls/engines/engine[3]/propeller-pitch", 0.7);
            } else {
              if(mach < 0.31) {
                setprop("/controls/engines/engine[0]/propeller-pitch", 0.65);
                setprop("/controls/engines/engine[1]/propeller-pitch", 0.65);
                setprop("/controls/engines/engine[2]/propeller-pitch", 0.65);
                setprop("/controls/engines/engine[3]/propeller-pitch", 0.65);
              } else {
                if(mach < 0.32) {
                  setprop("/controls/engines/engine[0]/propeller-pitch", 0.6);
                  setprop("/controls/engines/engine[1]/propeller-pitch", 0.6);
                  setprop("/controls/engines/engine[2]/propeller-pitch", 0.6);
                  setprop("/controls/engines/engine[3]/propeller-pitch", 0.6);
                } else {
                  if(mach < 0.33) {
                    setprop("/controls/engines/engine[0]/propeller-pitch", 0.5);
                    setprop("/controls/engines/engine[1]/propeller-pitch", 0.5);
                    setprop("/controls/engines/engine[2]/propeller-pitch", 0.5);
                    setprop("/controls/engines/engine[3]/propeller-pitch", 0.5);
                  } else {
                    setprop("/controls/engines/engine[0]/propeller-pitch", 0.4);
                    setprop("/controls/engines/engine[1]/propeller-pitch", 0.4);
                    setprop("/controls/engines/engine[2]/propeller-pitch", 0.4);
                    setprop("/controls/engines/engine[3]/propeller-pitch", 0.4);
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
toggle_traj_mkr = func {
  if(getprop("/ai/submodels/trajectory-markers") == nil) {
    setprop("/ai/submodels/trajectory-markers", 0);
  }
  if(getprop("/ai/submodels/trajectory-markers") < 1) {
    setprop("/ai/submodels/trajectory-markers", 1);
  } else {
    setprop("/ai/submodels/trajectory-markers", 0);
  }
}
#--------------------------------------------------------------------
initialise_drop_view_pos = func {
  eyelatdeg = getprop("/position/latitude-deg");
  eyelondeg = getprop("/position/longitude-deg");
  eyealtft = getprop("/position/altitude-ft") + 20;
  setprop("/sim/view[101]/latitude-deg", eyelatdeg);
  setprop("/sim/view[101]/longitude-deg", eyelondeg);
  setprop("/sim/view[101]/altitude-ft", eyealtft);
}
#--------------------------------------------------------------------
update_drop_view_pos = func {
  eyelatdeg = getprop("/position/latitude-deg");
  eyelondeg = getprop("/position/longitude-deg");
  eyealtft = getprop("/position/altitude-ft") + 20;
  interpolate("/sim/view[101]/latitude-deg", eyelatdeg, 5);
  interpolate("/sim/view[101]/longitude-deg", eyelondeg, 5);
  interpolate("/sim/view[101]/altitude-ft", eyealtft, 5);
}
#--------------------------------------------------------------------
update_tower_view_pos = func {
  towerlatdeg = getprop("/position/latitude-deg");
  towerlondeg = getprop("/position/longitude-deg");
  acaltft = getprop("/position/altitude-ft");
  acaglft = getprop("/position/altitude-agl-ft");
  toweraltft = acaltft - acaglft;
  setprop("/sim/tower/latitude-deg", towerlatdeg);
  setprop("/sim/tower/longitude-deg", towerlondeg);
  setprop("/sim/tower/altitude-ft", toweraltft);
}
#--------------------------------------------------------------------
start_up = func {
  settimer(initialise_drop_view_pos, 5);
#  settimer(auto_prop_pitch, 5);
}
#--------------------------------------------------------------------

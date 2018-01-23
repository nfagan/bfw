function binned = get_binned_sync_pulses( pl2_file, pl2_map )

if ( nargin < 2 )
  pl2_map = bfw.get_plex_channel_map();
end

sync_pulse_raw = PL2Ad( pl2_file, pl2_map('sync_pulse') );
start_pulse_raw = PL2Ad( pl2_file, pl2_map('session_start') );

ai_fs = start_pulse_raw.ADFreq;

sync_pulses = bfw.get_pulse_indices( sync_pulse_raw.Values );
start_pulses = bfw.get_pulse_indices( start_pulse_raw.Values );

binned = bfw.bin_pulses( sync_pulses, start_pulses );

end
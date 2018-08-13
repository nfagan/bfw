function map = get_plex_channel_map()

map = containers.Map();
map('session_start') = 'AI02';
map('sync_pulse') = 'AI03';
map('reward') = 'AI04';
map('stimulation') = 'AI07';
map('sham_stimulation') = 'AI08';

end
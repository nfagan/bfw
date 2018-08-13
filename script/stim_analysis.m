pl2_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/free_viewing/raw/04202018/plex/unsorted/KuroLynch_042018.pl2';
stim_chan = 'AI07';
sham_chan = 'AI08';

stim_events = PL2Ad( pl2_file, stim_chan );
sham_events = PL2Ad( pl2_file, sham_chan );

fp_times = (0:numel(stim_events.Values)-1) .* 1/stim_events.ADFreq;

info = PL2GetFileIndex( pl2_file );

%%

thresh = 4.93;

stim_events = shared_utils.logical.find_all_starts( stim_events.Values > thresh );
sham_events = shared_utils.logical.find_all_starts( sham_events.Values > thresh );

%%

% all_wb = PL2Ad( pl2_file, 'FP09' );

all_wb = PL2Ad( pl2_file, 'WB09' );
id_times = (0:numel(all_wb.Values)-1) .* 1/all_wb.ADFreq;

%%

evt = stim_events(30);
fp_time = fp_times(evt);

[~, I] = min( abs(id_times - fp_time) );

look_back = -1 * all_wb.ADFreq;
look_ahead = 1 * all_wb.ADFreq;

hold off;

plot( look_back:look_ahead, all_wb.Values(I+look_back:I+look_ahead) );
hold on;
plot( [0; 0], get(gca, 'ylim'), 'k--' );

%%

ind = I+look_back:I+look_ahead;
subset = all_wb.Values(ind);
low_ind = subset < 0 & subset > -2;
high_ind = subset > 0;








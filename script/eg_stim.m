function bounds = eg_stim()

stim_p = bfw.get_intermediate_directory( 'stim' );
bounds_p = bfw.get_intermediate_directory( 'bounds' );
aligned_p = bfw.get_intermediate_directory( 'aligned' );
unified_p = bfw.get_intermediate_directory( 'unified' );

mats = bfw.require_intermediate_mats( [], stim_p, [] );

look_back = 0;
look_ahead = 5e3;

t_series = look_back:look_ahead;
bounds_psth = [];
bounds_labs = fcat.with( {'unified_filename', 'stim_type', 'date', 'day'} );

for i = 1:numel(mats)

stim_file = shared_utils.io.fload( mats{i} );

un_filename = stim_file.unified_filename;

aligned = shared_utils.io.fload( fullfile(aligned_p, un_filename) );
bounds_file = shared_utils.io.fload( fullfile(bounds_p, un_filename) );
un_file = shared_utils.io.fload( fullfile(unified_p, un_filename) );

date_str = un_file.m1.date;
day_str = datestr( date_str, 'mmddyy' );

m1_plex_t = aligned.m1.plex_time;
m1_mat_t = aligned.m1.time;
m1_bounds_t = bounds_file.m1.time;

first_t = min( find(m1_plex_t > 0) );

m1_plex_t = m1_plex_t(first_t:end);
m1_mat_t = m1_mat_t(first_t:end);

bounds = bounds_file.m1.bounds('eyes');

stp_size = bounds_file.step_size;

labs = fcat.like( bounds_labs );
labs('unified_filename') = stim_file.unified_filename;
labs('stim_type') = 'stimulate';
labs('date') = date_str;
labs('day') = day_str;

for j = 1:numel(stim_file.stimulation_times)
  stim_t = stim_file.stimulation_times(j);

  [~, I] = min( abs(m1_plex_t - stim_t) );
  mat_t = m1_mat_t(I);
  [~, mat_I] = min( abs(m1_bounds_t - mat_t) );
  
  ib = bounds(mat_I+look_back/stp_size:mat_I+look_ahead/stp_size);
  
  bounds_psth = [ bounds_psth; ib ];
end

repmat( labs, numel(stim_file.stimulation_times) );

append( bounds_labs, labs );

labs = fcat.like( bounds_labs );

for j = 1:numel(stim_file.sham_times)
  stim_t = stim_file.sham_times(j);

  [~, I] = min( abs(m1_plex_t - stim_t) );
  mat_t = m1_mat_t(I);
  [~, mat_I] = min( abs(m1_bounds_t - mat_t) );
  
  ib = bounds(mat_I+look_back/stp_size:mat_I+look_ahead/stp_size);
  
  bounds_psth = [ bounds_psth; ib ];
end

resize( labs, 1 );

labs('stim_type') = 'sham';
labs('unified_filename') = stim_file.unified_filename;
labs('date') = date_str;
labs('day') = day_str;

repmat( labs, numel(stim_file.sham_times) );

append( bounds_labs, labs );

end

bounds = labeled( bounds_psth, bounds_labs );

end
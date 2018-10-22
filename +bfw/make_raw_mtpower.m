function make_raw_mtpower(varargin)

defaults = bfw.get_common_make_defaults();
defaults = bfw.get_common_lfp_defaults( defaults );
defaults.step_size = 50;
defaults.chronux_params = struct( ...
  'tapers', [1.5, 2] ...
);

params = bfw.parsestruct( defaults, varargin );

conf = params.config;
isd = params.input_subdir;
osd = params.output_subdir;

params.chronux_params.Fs = params.sample_rate;

lfp_p = bfw.gid( fullfile('raw_aligned_lfp', isd), conf );
pow_p = bfw.gid( fullfile('raw_mtpower', osd), conf );

mats = bfw.require_intermediate_mats( params.files, lfp_p, params.files_containing );

for i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  lfp_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = lfp_file.unified_filename;
  output_filename = fullfile( pow_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    pow_file = power_main( lfp_file, params );
    
    shared_utils.io.require_dir( pow_p );
    shared_utils.io.psave( output_filename, pow_file, 'pow_file' );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

function pow_file = power_main(lfp_file, params)

lfp = lfp_file.data;
event_indices = lfp_file.event_indices;
labels = fcat.from( lfp_file.labels, lfp_file.categories );

look_back = lfp_file.params.look_back;
look_ahead = lfp_file.params.look_ahead;

window_size = lfp_file.params.window_size;
step_size = params.step_size;
chronux_params = params.chronux_params;

lfp = handle_filtering( lfp, params );
[lfp, was_ref_subtracted] = handle_reference( lfp, labels, event_indices, params );

windowed_data = shared_utils.array.bin3d( lfp, window_size, step_size );
n_time_bins = size( windowed_data, 3 );

all_labels = fcat();
all_dat = [];
all_event_indices = [];

I = findall( labels, {'region', 'channel'} );

for i = 1:numel(I)
  ind = I{i};
  
  for j = 1:n_time_bins
    one_t_a = squeeze( windowed_data(ind, :, j) )';

    [p, f] = mtspectrumc( one_t_a, chronux_params );

    p = p';

    if ( j == 1 )
      pxx = nan( [size(p), n_time_bins] );
    end

    pxx(:, :, j) = p;
  end
  
  all_dat = [ all_dat; pxx ];
  all_event_indices = [ all_event_indices; columnize(event_indices(ind)) ];
  append( all_labels, labels, ind );
end

assert_ispair( all_dat, all_labels );

pow_file = struct();
pow_file.params = params;
pow_file.unified_filename = lfp_file.unified_filename;
pow_file.data = all_dat;
pow_file.labels = categorical( all_labels );
pow_file.categories = getcats( all_labels );
pow_file.f = f;
pow_file.t = look_back:step_size:look_ahead;
pow_file.event_indices = all_event_indices;
pow_file.was_reference_subtracted = was_ref_subtracted;

end

function [data, was_ref_subtracted] = handle_reference(data, labels, event_indices, params)

was_ref_subtracted = false;

if ( ~params.reference_subtract ), return; end

[data, was_ref_subtracted] = bfw.ref_subtract_fcat( data, labels, event_indices );

end

function data = handle_filtering(data, params)

if ( ~params.filter )
  return
end

f1 = params.f1;
f2 = params.f2;
filt_order = params.filter_order;
fs = params.sample_rate;
data = bfw.zpfilter( data, f1, f2, fs, filt_order );

end
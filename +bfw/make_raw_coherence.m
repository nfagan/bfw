function make_raw_coherence(varargin)

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
rng_p = bfw.gid( fullfile('rng', isd), conf );
coh_p = bfw.gid( fullfile('raw_coherence', osd), conf );

mats = bfw.require_intermediate_mats( params.files, lfp_p, params.files_containing );

parfor i = 1:numel(mats)
  shared_utils.general.progress( i, numel(mats) );
  
  lfp_file = shared_utils.io.fload( mats{i} );
  
  unified_filename = lfp_file.unified_filename;
  output_filename = fullfile( coh_p, unified_filename );
  
  if ( bfw.conditional_skip_file(output_filename, params.overwrite) )
    continue;
  end
  
  try
    rng_file = shared_utils.io.fload( fullfile(rng_p, unified_filename) );
    coh_file = coherence_main( lfp_file, rng_file, params );
    
    shared_utils.io.require_dir( coh_p );
    shared_utils.io.psave( output_filename, coh_file, 'coh_file' );
  catch err
    bfw.print_fail_warn( unified_filename, err.message );
    continue;
  end
end

end

function coh_file = coherence_main(lfp_file, rng_file, params)

lfp = lfp_file.data;
event_indices = lfp_file.event_indices;
labels = fcat.from( lfp_file.labels, lfp_file.categories );

look_back = lfp_file.params.look_back;
look_ahead = lfp_file.params.look_ahead;

window_size = lfp_file.params.window_size;
step_size = params.step_size;
chronux_params = params.chronux_params;

regions = combs( labels, 'region' );
n_regions = numel( regions );

assert( n_regions > 1, 'Too few regions to calculate coherence.' );

lfp = handle_filtering( lfp, params );
[lfp, was_ref_subtracted] = handle_reference( lfp, labels, event_indices, params );

inds = nchoosek( columnize(1:n_regions), 2 );

windowed_data = shared_utils.array.bin3d( lfp, window_size, step_size );
n_time_bins = size( windowed_data, 3 );

stp = 1;
all_labels = fcat();
all_dat = [];
all_event_indices = [];

for i = 1:rows(inds)
  reg_a = regions{inds(i, 1)};
  reg_b = regions{inds(i, 2)};
  
  mask_a = find( labels, reg_a );
  mask_b = find( labels, reg_b );
  
  channels_a = combs( labels, 'channel', mask_a );
  channels_b = combs( labels, 'channel', mask_b );
  
  chans_a = cellfun( @(x) str2double(x(3:4)), channels_a );
  chans_b = cellfun( @(x) str2double(x(3:4)), channels_b );
  
  need_choose_pairs = numel( chans_a ) > 1 && numel( chans_b ) > 1;
  
  if ( need_choose_pairs )
    % make sure pair selection is deterministic
    rng_prev_state = rng( rng_file.state );
    
    pairs = bfw.select_pairs( chans_a, chans_b, 16 );
    
    rng( rng_prev_state );
  else
    n_use = max( numel(chans_a), numel(chans_b) );
    pairs = zeros( n_use, 2 );
    
    pairs(:, 1) = chans_a;
    pairs(:, 2) = chans_b;
  end
  
  for j = 1:rows(pairs)
    chan_a = bfw.num2str_zeropad( 'FP', pairs(j, 1) );
    chan_b = bfw.num2str_zeropad( 'FP', pairs(j, 2) );
    
    ind_a = find( labels, chan_a, mask_a );
    ind_b = find( labels, chan_b, mask_b );
    
    assert( isequal(event_indices(ind_a), event_indices(ind_b)) );
    
    for k = 1:n_time_bins
      one_t_a = squeeze( windowed_data(ind_a, :, k) )';
      one_t_b = squeeze( windowed_data(ind_b, :, k) )';
      
      [C, ~, ~, ~, ~, f] = coherencyc( one_t_a, one_t_b, chronux_params );
      
      C = C';
      
      if ( k == 1 )
        coh = nan( [size(C), n_time_bins] );
      end
      
      coh(:, :, k) = C;      
    end
    
    assign_idx = stp:stp+numel(ind_a)-1;
    
    stp = stp + numel(ind_a);
    
    append( all_labels, labels, ind_a );
    setcat( all_labels, 'region', sprintf('%s_%s', reg_a, reg_b), assign_idx );
    setcat( all_labels, 'channel', sprintf('%s_%s', chan_a, chan_b), assign_idx );
    
    all_dat = [ all_dat; coh ];
    all_event_indices = [ all_event_indices; columnize(event_indices(ind_a)) ];
  end
end

assert_ispair( all_dat, all_labels );

coh_file = struct();
coh_file.params = params;
coh_file.unified_filename = lfp_file.unified_filename;
coh_file.data = all_dat;
coh_file.labels = categorical( all_labels );
coh_file.categories = getcats( all_labels );
coh_file.f = f;
coh_file.t = look_back:step_size:look_ahead;
coh_file.event_indices = all_event_indices;
coh_file.was_reference_subtracted = was_ref_subtracted;

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
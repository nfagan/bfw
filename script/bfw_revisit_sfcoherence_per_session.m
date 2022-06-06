function bfw_revisit_sfcoherence_per_session(event_ts, event_labs, event_each, varargin)

assert_ispair( event_ts, event_labs );

defaults = struct();
defaults.config = bfw.config.load();
defaults.mask_func = @(l, m) intersect(m, rowmask(l));
params = shared_utils.general.parsestruct( defaults, varargin );

conf = params.config;

%%

lfp_p = bfw.gid( 'lfp', conf );
spk_p = bfw.gid( 'cc_spikes', conf );

base_dst_p = bfw.gid( 'sfcoherence', conf );

lfp_files = shared_utils.io.findmat( lfp_p );
[ps, exists] = bfw.match_files( lfp_files ...
  , spk_p ...
  , bfw.gid('meta', conf) ...
);

to_process = ps(all(exists, 2), :);
has_first = cellfun( @(x) contains(x, '_1.mat'), to_process(:, 1) );
to_process = to_process(has_first, :);

no_nans = @(C) ~squeeze( any(any(isnan(C), 3), 2) );
not_all_nans = @(C) ~squeeze( all(all(isnan(C), 3), 2) );

for i = 1:size(to_process, 1)
  fprintf( '\n %d of %d', i, size(to_process, 1) );
  
  ps = to_process(i, :);
  lfp_file = bfw.load_linked( ps{1} );
  spike_file = bfw.load_linked( ps{2} );
  meta_file = shared_utils.io.fload( ps{3} );
  
  %%
  
  lfp_regs = bfw.standardize_regions( lfp_file.key(:, 2) );
  spk_regs = bfw.standardize_regions( {spike_file.data.region} );
  
  ref_ind = strcmp( lfp_regs, 'ref' );
  if ( nnz(ref_ind) == 0 )
    warning( 'No ref region for "%s".', meta_file.unified_filename );
    continue
  end
  
  lfp = bfw.lfp_preprocess( lfp_file.data, 'ref_index', find(ref_ind) );
  lfp_regs = lfp_regs(~ref_ind, :);
  spks = { spike_file.data.times };
  
  lfp_labels = lfp_file.key(~ref_ind, :);
  
  %%
  
  pairs = bfw.nonmatching_pairs( spk_regs, lfp_regs )';
%   pairs = pairs(1:8, :);
  pairs = at_most_n_lfp_channels( pairs, 1 );
  
  %%
  
  mask = params.mask_func( event_labs, find(event_labs, meta_file.session) );
  [subset_I, subset_C] = findall( event_labs, event_each, mask );
  
  for j = 1:numel(subset_I)
    fprintf( '\n\t %d of %d', j, numel(subset_I) );
    
    event_mask = subset_I{j};
    if ( isempty(event_mask) )
      continue
    end
    
    subset_event_ts = event_ts(event_mask);
    [coh, ~, f, t, info] = bfw.sfcoherence( spks, lfp, subset_event_ts, pairs ...
      , 'f_lims', [0, 85] ...
      , 'keep_if', not_all_nans ...
      , 'single_precision', true ...
    );
    
    labs = make_labels( spike_file.data, lfp_labels ...
      , bfw.struct2fcat(meta_file), event_labs(event_mask), pairs, info.inds );
    coh = vertcat( coh{:} );    
%     phi = vertcat( phi{:} );
    assert_ispair( coh, labs );
    dst_file = make_file( coh, labs, f, t, info, meta_file.unified_filename );
    
    if ( 1 )
      each_p = strjoin( subset_C(:, j), '_' );
      dst_file_path = fullfile( base_dst_p, each_p, meta_file.unified_filename );
      shared_utils.io.require_dir( fileparts(dst_file_path) );
      shared_utils.io.psave( dst_file_path, dst_file );
    end
  end
  
end

end

function dst_file = make_file(coh, labs, f, t, info, unified_filename)

dst_file = struct();
dst_file.unified_filename = unified_filename;
[dst_file.labels, dst_file.categories] = categorical( labs );
dst_file.data = coh;
dst_file.f = f;
dst_file.t = t;
dst_file.info = info;

end

function l = make_labels(units, lfp_labels, meta_labels, event_labels, pairs, inds)

assert( size(pairs, 1) == numel(inds) );

l = fcat();

for i = 1:size(pairs, 1)
  spk_labs = bfw.unit_struct_to_fcat( units(pairs(i, 1)) );
  
  spk_chan = cellstr( spk_labs, 'channel' );
  lfp_chan = lfp_labels(pairs(i, 2), 1);
  spk_lfp_chan = strjoin( [spk_chan, lfp_chan], '_' );
  setcat( spk_labs, 'channel', spk_lfp_chan );
  
  spk_reg = cellstr( spk_labs, 'region' );
  lfp_reg = lfp_labels(pairs(i, 2), 2);
  spk_lfp_reg = strjoin( [spk_reg, lfp_reg], '_' );
  setcat( spk_labs, 'region', spk_lfp_reg );
  
  join( spk_labs, meta_labels );
  li = join( event_labels', spk_labs );  
  li = li(inds{i});  
  
  if ( i == 1 )
    l = li;
  else
    append( l, li );
  end
end

end

function pairs = at_most_n_lfp_channels(pairs, n)

[~, ~, ic] = unique( pairs(:, 1) );
ic = groupi( ic );
ic = cellfun( @(x) x(1:min(n, numel(x))), ic, 'un', 0 );
pairs = pairs(vertcat(ic{:}), :);

end
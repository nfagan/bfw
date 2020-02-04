function summarize_positional_info(varargin)

defaults = bfw.get_common_plot_defaults( bfw.get_common_make_defaults() );
defaults.config = bfw_st.default_config();
defaults.pos_outs = [];
defaults.mask_func = @(labels, mask) mask;

params = bfw.parsestruct( defaults, varargin );
pos_outs = params.pos_outs;

if ( isempty(pos_outs) )
  pos_outs = bfw_st.positional_info( ...
      'source_rois', 'eyes_nf' ...
    , 'target_rois', 'eyes_nf' ...
    , 'use_events', false ...
    , 'files_containing', bfw_st.included_sessions() ...
  );
end

%%

labels = pos_outs.distance_labels';
rel_starts = pos_outs.relative_start_times;
distances = pos_outs.distances;

mark_first_fixations( rel_starts, labels );

%%

summary_levels = { 'day', 'trial' };
only_first_fixations = [ false, true ];

cmbtns = dsp3.numel_combvec( summary_levels, only_first_fixations );
num_combs = size( cmbtns, 2 );

for idx = 1:num_combs
  cmbtn = cmbtns(:, idx);
  summary_level = summary_levels{cmbtn(1)};
  only_first_fixation = only_first_fixations(cmbtn(2));

  before_plot_funcs = {};
  mask_func_inputs = {};

  fcats = {};
  pcats = {};
  gcats = {};
  xcats = {};

  points_are = {};
  add_points = false;

  base_subdir = '';

  if ( strcmp(summary_level, 'day') )
    before_plot_funcs{end+1} = @bfw_st.day_level_average;
    base_subdir = extend_base_subdir( base_subdir, '_day_level_average' );

    add_points = true;
    points_are = { 'session' };
  else
    before_plot_funcs{end+1} = @keep_all_trials;
    base_subdir = extend_base_subdir( base_subdir, '_trial_level_average' );
  end

  if ( only_first_fixation )
    mask_func_inputs = [ mask_func_inputs, {@find, 'first_fixation__true'} ];
    base_subdir = extend_base_subdir( base_subdir, '_first_fixation_only' );
  else
    base_subdir = extend_base_subdir( base_subdir, '_all_fixations' );
  end

  mask_func = @(l, m) fcat.mask( l, m, mask_func_inputs{:} );
  before_plot_func = @(varargin) apply_functions( before_plot_funcs, varargin{:} );
  base_subdir = trim_base_subdir( base_subdir );

  bfw_st.plot_positional_info( distances, labels ...
    , 'config', params.config ...
    , 'fcats', fcats, 'pcats', pcats, 'gcats', gcats, 'xcats', xcats ...
    , 'add_points', add_points ...
    , 'points_are', points_are ...
    , 'before_plot_func', before_plot_func ...
    , 'mask_func', wrap_mask_func(mask_func, params.mask_func) ...
    , 'base_subdir', base_subdir ...
    , 'do_save', params.do_save ...
  );
end

end

function bs = trim_base_subdir(bs)

if ( ~isempty(bs) && bs(1) == '_' )
  bs = bs(2:end);
end

end

function bs = extend_base_subdir(orig, new)
bs = sprintf( '%s%s', orig, new );
end

function [data, labels, mask] = keep_all_trials(data, labels, spec, mask)

data = rowref( data, mask );
labels = labels(mask);
mask = rowmask( data );

end

function [data, labels] = apply_functions(functions, data, labels, spec, mask)

for i = 1:numel(functions)
  [data, labels, mask] = functions{i}( data, labels, spec, mask );
end

end

function wrapped_mask_func = wrap_mask_func(mask_func, base_mask_func)

wrapped_mask_func = @(labels, mask) base_mask_func(labels, mask_func(labels, mask));

end

function labels = mark_first_fixations(rel_starts, labels)

mask = fcat.mask( labels ...
  , @find, bfw_st.included_sessions() ...
);

first_each = { 'event_type', 'looks_by', 'source_roi', 'target_roi', 'stim_trial_uuid' };

first_I = findall( labels, first_each, mask );
first_inds = cellfun( @(x) x(minindex(rel_starts(x))), first_I );

addcat( labels, 'first_fixation' );
setcat( labels, 'first_fixation', 'first_fixation__true', first_inds );
setcat( labels, 'first_fixation', 'first_fixation__false', setdiff(mask, first_inds) );

prune( labels );

end
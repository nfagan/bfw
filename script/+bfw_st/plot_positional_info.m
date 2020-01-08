pos_outs = bfw_st.positional_info( ...
    'source_rois', 'eyes_nf' ...
  , 'target_rois', 'eyes_nf' ...
);

%%

labels = pos_outs.distance_labels';
rel_starts = pos_outs.relative_start_times;
dists = pos_outs.distances;

included_sessions = bfw_st.included_sessions();

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

%%
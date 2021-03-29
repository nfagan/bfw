look_vec = bfw_make_looking_vector( ...
    'samples_subdir', 'aligned_binned_raw_samples' ...
  , 'rois', 'eyes_nf' ...
);

%%

look_vec_20 = shared_utils.io.fload( fullfile(bfw.dataroot, 'public/look_vector_20.mat') );
% look_vec_30 = shared_utils.io.fload( fullfile(bfw.dataroot, 'public/look_vector_30.mat') );

%%

look_vec = look_vec_20;

%%

figure(1);
clf();
p_in_bounds30 = cellfun( @pnz, look_vec_30.look_vectors );
p_in_bounds20 = cellfun( @pnz, look_vec_20.look_vectors );

ax1 = subplot( 1, 2, 1 );
hist( ax1, p_in_bounds20, 100 );
ax2 = subplot( 1, 2, 2 );
hist( ax2, p_in_bounds30, 100 );


%%

events = bfw_gather_events( 'require_stim_meta', false );
spikes = bfw_gather_spikes( 'spike_subdir', 'cc_spikes' );

%%

event_mask_func = @(l, m) pipe(m ...
  , @(m) find(l, 'eyes_nf', m) ...
  , @(m) find(l, 'free_viewing', m) ...
);

event_res = bfw_define_interactive_events( events, look_vec, 'mask_func', event_mask_func );

%%

import BFWInteractiveEventClassification.m2_initiator_m1_follower;
import BFWInteractiveEventClassification.m1_initiator_m2_follower;

event_start_stops = [ bfw.event_column(events, 'start_index') ...
                    , bfw.event_column(events, 'stop_index') ];

event_mask_func = @(l, m) pipe(m ...
  , @(m) find(l, 'eyes_nf', m) ...
  , @(m) find(l, 'free_viewing', m) ...
);

event_mask = event_mask_func( events.labels, rowmask(events.labels) );
[each_I, each_C] = findall( events.labels, {'unified_filename', 'roi'}, event_mask );
                  
follow_range = 1e3; % ms
include_mutual = false;

interactive_labels = events.labels';
addsetcat( interactive_labels, 'event-type', 'unclassified-type' );

for i = 1:numel(each_I)
  shared_utils.general.progress( i, numel(each_I) );
  
  m1_gaze_ind = find( look_vec.labels, [each_C(:, i); {'m1'}] );
  m2_gaze_ind = find( look_vec.labels, [each_C(:, i); {'m2'}] );
  
  if ( numel(m1_gaze_ind) ~= 1 || numel(m2_gaze_ind) ~= 1 )
    continue;
  end
  
  m1_event_ind = find( events.labels, 'm1', each_I{i} );
  m2_event_ind = find( events.labels, 'm2', each_I{i} );
  mut_event_ind = find( events.labels, 'mutual', each_I{i} );
  
  m1_events = event_start_stops(m1_event_ind, :);
  m2_events = event_start_stops(m2_event_ind, :);
  mut_events = event_start_stops(mut_event_ind, :);
  
  m1_gaze = look_vec.look_vectors{m1_gaze_ind};
  m2_gaze = look_vec.look_vectors{m2_gaze_ind};
  
  [m1_event_types, m1_event_inds] = m2_initiator_m1_follower( m1_events, m2_events, m1_gaze, follow_range );
  [m2_event_types, m2_event_inds] = m1_initiator_m2_follower( m1_events, m2_events, m1_gaze, follow_range );
  
  setcat( interactive_labels, 'event-type', event_type_strs(m1_event_types), m1_event_ind );
  setcat( interactive_labels, 'event-type', event_type_strs(m2_event_types), m2_event_ind );
  
  if ( include_mutual )
    [mut_event_types, mut_looks_by, handled] = ...
      BFWInteractiveEventClassification.mutual( m1_events, m2_events, mut_events, m1_gaze, follow_range );

    setcat( interactive_labels, 'event-type', event_type_strs(mut_event_types), mut_event_ind );
    setcat( interactive_labels, 'looks_by', mut_looks_by, mut_event_ind );
  end
end

%%

mask = fcat.mask( interactive_labels ...
  , @findnone, 'unclassified-type' ...
  , @find, 'solo-type' ...
  %{
%   , @findnot, {'solo-type', 'm1'} ...
  %}
);

[cts, ct_labels] = counts_of( interactive_labels' ...
  , {'looks_by', 'roi', 'session'}, 'event-type', mask );

%%

% cts = orig_cts;
% ct_labels = orig_ct_labels';

pl = plotlabeled.make_common();
% pl.y_lims = [ 0, 26 ];
axs = pl.bar( cts, ct_labels, {'looks_by'}, {'event-type'}, {'roi'} );

%%


function strs = event_type_strs(event_types)

strs = BFWInteractiveEventClassification.event_type_to_cellstr( event_types );

end
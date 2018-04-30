function outs = debug__check_m1_sync()

import shared_utils.io.fload;

bounds_la = 3e3;
bounds_lb = -1e3;

un_p = bfw.get_intermediate_directory( 'unified' );
edf_p = bfw.get_intermediate_directory( 'edf' );
sync_p = bfw.get_intermediate_directory( 'sync' );
stim_p = bfw.get_intermediate_directory( 'stim' );
roi_p = bfw.get_intermediate_directory( 'rois' );

mats = bfw.require_intermediate_mats( [], stim_p, '04242018' );

all_outs = cell( 1, numel(mats) );

parfor i = 1:numel(mats)
  fprintf( '\n %d of %d', i, numel(mats) );
  
  stim_file = shared_utils.io.fload( mats{i} );
  
  un_filename = stim_file.unified_filename;
  
  un_file = fload( fullfile(un_p, un_filename) );
  edf_file = fload( fullfile(edf_p, un_filename) );
  sync_file = fload( fullfile(sync_p, un_filename) );
  roi_file = fload( fullfile(roi_p, un_filename) );
  
  one_outs = get_psths( un_file, sync_file, stim_file, roi_file, edf_file, bounds_la, bounds_lb );
  
  all_outs{i} = one_outs;
end

outs = merge_outs( all_outs );

end

function outs = merge_outs( all_outs )

outs = struct();

s = fieldnames( all_outs{1} );

for i = 1:numel(s)  
  is_cont = isa( all_outs{1}.(s{i}), 'Container' );
  
  if ( ~is_cont )
    outs.(s{i}) = all_outs{1}.(s{i});
    continue;
  end
  
  for j = 1:numel(all_outs)
    if ( j == 1 )
      outs.(s{i}) = Container();
    end
    
    if ( is_cont )
      outs.(s{i}) = append( outs.(s{i}), all_outs{j}.(s{i}) );
    end
  end
end

outs.p_inbounds_t = all_outs{1}.p_inbounds_t;

end

function outs = get_psths(un_file, sync_file, stim_file, roi_file, edf_file, bounds_la, bounds_lb)

un_filename = sync_file.unified_filename;

session_alias = sprintf( 'session__%d', un_file.m1.mat_index );

edf = edf_file.m1.edf;
rois = roi_file.m1.rects;

edf_t = edf.Samples.time;
edf_sync_t = edf.Events.Messages.time( strcmp(edf.Events.Messages.info, 'RESYNCH') );

mat_sync_t = sync_file.plex_sync(2:end, strcmp(sync_file.sync_key, 'mat'));
plex_sync_t = sync_file.plex_sync(2:end, strcmp(sync_file.sync_key, 'plex'));

to_mat_t = shared_utils.sync.clock_a_to_b( edf_t/1e3, edf_sync_t(:)/1e3, mat_sync_t(:) );
to_plex_t = shared_utils.sync.clock_a_to_b( to_mat_t, mat_sync_t(:), plex_sync_t(:) );

pos = [ edf.Samples.posX(:)'; edf.Samples.posY(:)' ];

is_fix = is_fixation( pos, to_plex_t(:)', 20, 15, 0.05 );
is_fix = is_fix(1:size(pos, 2));
is_fix = (is_fix == 1)';

is_fix(:) = true;

looks_to = 'eyes';
rect = rois(looks_to);

rect([1, 2]) = rect([1, 2]) - 15;
rect([3, 4]) = rect([3, 4]) + 15;

is_inbounds = bfw.bounds.rect( pos(1, :), pos(2, :), rect );
is_nan = isnan(pos(1, :)) | isnan(pos(2, :));

st = stim_file.stimulation_times;
sht = stim_file.sham_times;

[stim_psth, psth_t] = align_psth( is_inbounds & is_fix, to_plex_t, st, bounds_lb, bounds_la );
sham_psth = align_psth( is_inbounds & is_fix, to_plex_t, sht, bounds_lb, bounds_la );
nan_psth = align_psth( is_nan, to_plex_t, st, bounds_lb, bounds_la );

base_labs = SparseLabels.create( ...
    'date', un_file.m1.date ...
  , 'day', datestr(un_file.m1.date, 'mmddyy') ...
  , 'unified_filename', un_filename ...
  , 'session', session_alias ...
  , 'stim_type', 'stimulate' ...
  , 'meas_type', 'n_fix' ...
  , 'fix_n', '<fix_n>' ...
  , 'looks_to', looks_to ...
);

ib_labs = set_field( base_labs, 'meas_type', 'p_inbounds' );

stim_psth = Container( stim_psth, ib_labs );
sham_psth = Container( sham_psth, set_field(ib_labs, 'stim_type', 'sham') );
nan_psth = Container( nan_psth, set_field(ib_labs, 'stim_type', 'isnan') );

outs.p_inbounds = extend( stim_psth, sham_psth );
outs.p_inbounds_t = psth_t;

end

function [psth, t_series] = align_psth(bounds, bounds_t, event_ts, lb, la)

t_series = lb:la;
psth = nan( numel(event_ts), numel(t_series) );

for i = 1:numel(event_ts)
  [~, I] = min( abs(bounds_t - event_ts(i)) );
  ind = I+lb:I+la;
  
  if ( min(ind) < 1 || max(ind) > numel(bounds) )
    continue;
  end
  
  psth(i, :) = bounds(I+lb:I+la);
end

psth = sum(psth, 1) / size(psth, 1);

end



% inds = shared_utils.logical.find_all_starts( fix_vector );
% ind = inds(5);
% 
% la = 1e3;
% t_series = -la:la;
% 
% hold off; plot( t_series, pos(1, ind-la:ind+la), 'r' ); hold on;
% plot( t_series, pos(2, ind-la:ind+la), 'b' );
% 
% I = find( fix_vector(ind-la:ind+la) );
% 
% lims = get( gca, 'ylim' );
% 
% plot( t_series(I), mean(lims), 'k*', 'markersize', 0.2 );
% 
% 
% d = 10;
function bfw_check_image_task_stim_times(varargin)

defaults = bfw.get_common_make_defaults();
params = bfw.parsestruct( defaults, varargin );
conf = params.config;

task_event_mats = shared_utils.io.findmat( bfw.gid('image_task_events', conf) );
stim_p = bfw.gid( 'stim', conf );
meta_p = bfw.gid( 'meta', conf );

counts = [];
labels = fcat();

for i = 1:numel(task_event_mats)
  event_file = shared_utils.io.fload( task_event_mats{i} );
  stim_file = shared_utils.io.fload( fullfile(stim_p, event_file.unified_filename) );
  meta_file = shared_utils.io.fload( fullfile(meta_p, event_file.unified_filename) );
  
  stim_deactivated_t = event_file.m1.events(:, strcmp(event_file.event_key, 'stim_deactivated'));
  stim_reactivated_t = event_file.m1.events(:, strcmp(event_file.event_key, 'image_onset'));
  
  if ( any(isnan(stim_deactivated_t)) || any(isnan(stim_reactivated_t)) )
    continue;
  end
  
  stim_times = [ stim_file.sham_times(:); stim_file.stimulation_times(:) ];
  
  tmp_counts = nan( 1, 4 );
  tmp_counts(2) = 0;
  
  for j = 1:numel(stim_times)
    stim_t = stim_times(j);
    
    for k = 1:numel(stim_deactivated_t)-1
      deactivate_t = stim_deactivated_t(k);
      reactivate_t = stim_reactivated_t(k+1);
      
      assert( reactivate_t > deactivate_t );
      
      if ( stim_t >= deactivate_t && stim_t <= reactivate_t )
        disp( (reactivate_t - stim_t) * 1e3 );
        
        tmp_counts(2) = tmp_counts(2) + 1;
        tmp_counts(4) = min( tmp_counts(4), reactivate_t - stim_t );
      end
    end
  end
  
  tmp_counts(1) = numel( stim_times );
  
  counts = [ counts; tmp_counts ];
  append( labels, bfw.struct2fcat(meta_file) );
end

end

function events = alternative_mat_sync(events, mat_sync, plex_sync)

nearest_mat_onset = bfw.find_nearest( mat_sync, events );
error_amount = events(:) - mat_sync(nearest_mat_onset);

events = plex_sync(nearest_mat_onset) + error_amount;

end
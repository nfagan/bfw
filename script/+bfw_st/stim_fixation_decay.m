function outs = stim_fixation_decay(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();
defaults.look_back = -1e3;
defaults.look_ahead = 5e3;
defaults.bin_size = 25;
defaults.rect_padding = 0.1;
defaults.bin_func = @any;
defaults.num_day_time_quantiles = 2;
defaults.stim_isi_quantile_edges = [5, 10, 15];

inputs = { 'raw_events', 'aligned_raw_samples/position', 'aligned_raw_samples/time' ...
  , 'aligned_raw_samples/raw_eye_mmv_fixations' ...
  , 'unified', 'stim', 'stim_meta', 'meta', 'rois', 'plex_start_stop_times' };

[params, runner] = bfw.get_params_and_loop_runner( inputs, '', defaults, varargin );
runner.convert_to_non_saving_with_output();

results = runner.run( @check_bounds, params );
outputs = shared_utils.pipeline.extract_outputs_from_results( results );

if ( isempty(outputs) )
  outs = struct();
  outs.params = params;
  outs.t = [];
  outs.labels = fcat();
  outs.bounds = [];
else
  outs = shared_utils.struct.soa( outputs );
  outs.params = params;
end

end

function outs = check_bounds(files, params)

import shared_utils.*;

pos_file = general.get( files, 'position' );
t_file = general.get( files, 'time' );
stim_file = general.get( files, 'stim' );
roi_file = general.get( files, 'rois' );
meta_file = general.get( files, 'meta' );
stim_meta_file = general.get( files, 'stim_meta' );
start_time_file = general.get( files, 'plex_start_stop_times' );
events_file = general.get( files, 'raw_events' );

event_labels = fcat.from( events_file );
event_starts = bfw.event_column( events_file, 'start_time' );

[stim_times, stim_labs] = bfw_st.files_to_pair( stim_file, stim_meta_file, meta_file );

bfw_st.add_stim_isi_quantile_labels( stim_labs, stim_times, params.stim_isi_quantile_edges );
bfw_st.add_per_stim_labels( stim_labs, stim_times );
bfw_st.add_day_time_quantile_labels( stim_labs, stim_times, params.num_day_time_quantiles, start_time_file );

addcat( stim_labs, 'roi' );

stim_start_inds = bfw_it.find_nearest_stim_time( t_file.t, stim_times );

look_ahead = params.look_ahead;
look_back = params.look_back;
bin_amt = params.bin_size;

t_course = shared_utils.vector.slidebin( look_back:look_ahead, bin_amt, bin_amt, true );
t_course = cellfun( @(x) x(1), t_course );

rects = roi_file.m1.rects;
roi_names = keys( rects );

bounds = zeros( numel(stim_times) * numel(roi_names), numel(t_course) );

stp = 1;

labels = fcat();

for i = 1:numel(stim_times)  
  t_course_ind = (stim_start_inds(i) + look_back):(stim_start_inds(i)+look_ahead);
  left_over = numel( t_file.t ) - max( t_course_ind );
  
  if ( left_over < 0 )
    t_course_ind(t_course_ind > numel(t_file.t)) = [];
  end
  
  m1_pos = pos_file.m1(:, t_course_ind);
  
  for j = 1:numel(roi_names)  
%     roi_event_ind = find( event_labels, {'m1', roi_names{j}} );
%     next_start = find( event_starts(roi_event_ind) > stim_times(i) , 1 , 'first' );
%     
%     if ( isempty(next_start) )
%         next_start = nan;
%     end
%     
%     if ( isnan(next_start) || next_start < 1 )
%         next_start = nan;
%     end
%     
%     prev_roi_ind = next_start-1;
%     prev_start = event_start(curr_dur_ind(prev_roi_ind));
%     iti = next_start - prev_start;
      
    current_rect = rects(roi_names{j});
    
    ib = bfw.bounds.rect( m1_pos(1, :), m1_pos(2, :), current_rect );
    ib = shared_utils.vector.slidebin( ib, bin_amt, bin_amt, true );

    tmp_bounds = cellfun( @(x) params.bin_func(double(x)), ib );

    if ( numel(tmp_bounds) < numel(t_course) )
      tmp_bounds(end+1:numel(t_course)) = 0;
    end

    bounds(stp, :) = tmp_bounds;
    stp = stp + 1;
    
    append1( labels, stim_labs, i );
    setcat( labels, 'roi', roi_names{j}, rows(labels) );
  end
end

outs = struct();
outs.t = t_course;
outs.bounds = bounds;
outs.labels = labels;

end

function apply_preceding_stim_duration_quantile_labels(src_labels, dest_labels)

quant_cat = 'preceding_stim_duration_quantile';
addcat( dest_labels, quant_cat );
[src_stim_id_I, src_stim_ids] = findall( src_labels, 'stim_id' );

for i = 1:numel(src_stim_id_I)
  dest_stim_ind = find( dest_labels, src_stim_ids{i} );
  src_label = cellstr( src_labels, quant_cat, src_stim_id_I{i} );
  setcat( dest_labels, quant_cat, src_label, dest_stim_ind );  
end

end

function add_preceding_stim_duration_quantile_labels(durations, labels)

each = day_event_specificity();
[quants, each_I] = dsp3.quantiles_each( durations, labels, 2, each, {} );
dsp3.add_quantile_labels( labels, quants, 'preceding_stim_duration_quantile' );

end
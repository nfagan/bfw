function outs = stim_fixation_decay(varargin)

defaults = bfw.get_common_make_defaults();
defaults.config = bfw_st.default_config();
defaults.look_back = -1e3;
defaults.look_ahead = 1e3;
defaults.bin_size = 25;
defaults.rect_padding = 0.1;
defaults.bin_func = @any;

inputs = { 'aligned_raw_samples/position', 'aligned_raw_samples/time' ...
  , 'aligned_raw_samples/raw_eye_mmv_fixations' ...
  , 'unified', 'stim', 'stim_meta', 'meta', 'rois' };

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

un_file = general.get( files, 'unified' );
pos_file = general.get( files, 'position' );
t_file = general.get( files, 'time' );
stim_file = general.get( files, 'stim' );
roi_file = general.get( files, 'rois' );
meta_file = general.get( files, 'meta' );
stim_meta_file = general.get( files, 'stim_meta' );

stim_times = [ stim_file.stimulation_times(:); stim_file.sham_times(:) ];
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

stim_labs = bfw.make_stim_labels( numel(stim_file.stimulation_times), numel(stim_file.sham_times) );
join( stim_labs, bfw.struct2fcat(meta_file), bfw.stim_meta_to_fcat(stim_meta_file) );
addcat( stim_labs, 'roi' );

labels = fcat();

for i = 1:numel(stim_times)  
  t_course_ind = (stim_start_inds(i) + look_back):(stim_start_inds(i)+look_ahead);
  left_over = numel( t_file.t ) - max( t_course_ind );
  
  if ( left_over < 0 )
    t_course_ind(t_course_ind > numel(t_file.t)) = [];
  end
  
  m1_pos = pos_file.m1(:, t_course_ind);
  
  for j = 1:numel(roi_names)  
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

bfw.get_region_labels( labels );
bfw.add_monk_labels( labels );

outs = struct();
outs.t = t_course;
outs.bounds = bounds;
outs.labels = labels;

end
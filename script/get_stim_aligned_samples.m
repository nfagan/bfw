function outs = get_stim_aligned_samples(varargin)

defaults = bfw.get_common_make_defaults();
defaults.look_back = -1;
defaults.look_ahead = 5;
defaults.samples_subdir = 'aligned_binned_raw_samples';
defaults.fixations_subdir = 'arduino_fixations';

params = bfw.parsestruct( defaults, varargin );

conf = params.config;

stim_files = bfw.require_intermediate_mats( params.files, bfw.gid('stim', conf) ...
  , params.files_containing );

empties = false( numel(stim_files), 1 );

c = cell( size(empties) );

all_is_in_bounds = c;
all_is_fix = c;
all_t_series = c;
all_ib_labs = c;
all_x = c;
all_y = c;

la = params.look_ahead;
lb = params.look_back;

ssd = params.samples_subdir;
fsd = params.fixations_subdir;

samples_p = bfw.gid( ssd, conf );
meta_p =    bfw.gid( 'meta', conf );

parfor idx = 1:numel(stim_files)
  shared_utils.general.progress( idx, numel(stim_files), mfilename );
  
  stim_file = shared_utils.io.fload( stim_files{idx} );
  
  un_filename = stim_file.unified_filename;
  
  should_continue = true;

  try
    bounds_file = shared_utils.io.fload( fullfile(samples_p, 'bounds', un_filename) );
    fix_file = shared_utils.io.fload( fullfile(samples_p, fsd, un_filename) );
    t_file = shared_utils.io.fload( fullfile(samples_p, 'time', un_filename) );
    pos_file = shared_utils.io.fload( fullfile(samples_p, 'position', un_filename) );
    meta_file = shared_utils.io.fload( fullfile(meta_p, un_filename) );
  catch err
    warning( err.message );
    should_continue = false;
  end
  
  empties(idx) = ~should_continue;
  
  if ( should_continue )
    %   NOTE -- There's a bug in r2017a parfor related to using `continue` 
    %   in a parfor loop. Normally, we would simply employ `continue` in
    %   the catch block above, but doing so causes strange behavior.

    stim_times = stim_file.stimulation_times;
    sham_times = stim_file.sham_times;

    stim_events = [ stim_times(:); sham_times(:) ];
    
    if ( isempty(stim_events) )
      empties(idx) = true;
      continue;
    end
    
    stim_types = { 'stim', 'sham' };
    stim_indices = [ rowones(numel(stim_times)); repmat(2, numel(sham_times), 1) ];

    monk_ids = intersect( {'m1', 'm2'}, fieldnames(bounds_file) );
    roi_names = keys( bounds_file.(char(monk_ids{1})) );

    C = combvec( 1:numel(monk_ids), 1:numel(roi_names) );
    n_combs = size( C, 2 );

    t = t_file.t;
    sf = 1e3;

    if ( bounds_file.params.is_binned )
      sf = sf / bounds_file.params.step_size;
    end

    t_series = lb:1/sf:la;

    total_is_fix = false( numel(stim_events) * n_combs, numel(t_series) );
    is_in_bounds = false( size(total_is_fix) );
    subset_x = nan( size(total_is_fix) );
    subset_y = nan( size(total_is_fix) );

    ib_labs = fcat();

    stp = 1;

    for i = 1:numel(stim_events)
      evt = shared_utils.sync.nearest( t, stim_events(i) );

      start = evt + lb * sf;
      stop = evt + la * sf;

      assign_start = 1;
      assign_stop = size( total_is_fix, 2 );

      if ( start < 1 )
        assign_start = abs( start ) + 2;
        start = 1;
      end

      if ( stop > numel(t) )
        overflow = stop - numel( t );
        assign_stop = assign_stop - overflow;
        stop = numel( t );
      end

      stimlabs = fcat.create( ...
          'stim_type',          stim_types{stim_indices(i)} ...
        , 'stim_id',            sprintf('stim__%d', i) ...
        , 'roi',                '<roi>' ...
        , 'looks_by',           '<looks_by>' ...
        , 'unified_filename',   un_filename ...
        , 'session',            meta_file.session ...
        , 'date',               meta_file.date ...
        , 'task_type',          meta_file.task_type ...
        , 'uuid',               sprintf( '%s-%d', shared_utils.general.uuid(), i ) ...
      );

      for j = 1:n_combs
        monk_idx = C(1, j);      
        roi_idx = C(2, j);

        monk_id = monk_ids{monk_idx};
        roi_name = roi_names{roi_idx};

        bounds_container = bounds_file.(monk_id);
        fix_vec = fix_file.(monk_id);
        pos = pos_file.(monk_id);

        bounds = bounds_container(roi_name);

        is_in_bounds(stp, assign_start:assign_stop) = bounds(start:stop);
        total_is_fix(stp, assign_start:assign_stop) = fix_vec(start:stop);
        subset_x(stp, assign_start:assign_stop) = pos(1, start:stop);
        subset_y(stp, assign_start:assign_stop) = pos(2, start:stop);

        setcat( stimlabs, {'roi', 'looks_by'}, {roi_name, monk_id} );
        append( ib_labs, stimlabs );

        stp = stp + 1;
      end
    end

    all_is_in_bounds{idx} = is_in_bounds;
    all_is_fix{idx} = total_is_fix;
    all_t_series{idx} = t_series;
    all_ib_labs{idx} = ib_labs;
    all_x{idx} = subset_x;
    all_y{idx} = subset_y;
  end
end

all_is_in_bounds(empties) = [];
all_is_fix(empties) = [];
all_t_series(empties) = [];
all_ib_labs(empties) = [];
all_x(empties) = [];
all_y(empties) = [];

is_in_bounds = vertcat( all_is_in_bounds{:} );
is_fix = vertcat( all_is_fix{:} );
ib_labs = vertcat( fcat(), all_ib_labs{:} );
x = vertcat( all_x{:} );
y = vertcat( all_y{:} );

outs = struct();
outs.labels = ib_labs';
outs.is_in_bounds = is_in_bounds;
outs.is_fixation = is_fix;
outs.t = all_t_series{1};
outs.x = x;
outs.y = y;
outs.params = params;

end


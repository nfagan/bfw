evts = load( '~/Downloads/join_follow_evt_face.mat' );
[starts, types, labels] = bfw_lda.linearize_joint_event_info( evts, 'whole_face' );

%%

[day_I, days] = findall( labels, 'session' );
% days = days(1);

t_mats = shared_utils.io.findmat( bfw.gid('aligned_raw_samples/time') );

%%

fnames = shared_utils.io.filenames( t_mats );
no_dot = cellfun( @(x) x(1) ~= '.', fnames );
fnames = fnames(no_dot);
t_mats = t_mats(no_dot);

fname_days = eachcell( @(x) x(1:8), fnames );

pos_days = contains( fnames, 'position' );
pos_nums = cellfun( @(x) str2double(x(19:end)), fnames(pos_days) );

dot_days = contains( fnames, 'dot' );
dot_nums = cellfun( @(x) str2double(x(14:end)), fnames(dot_days) );

fname_nums = nan( size(fname_days) );
fname_nums(pos_days) = pos_nums;
fname_nums(dot_days) = dot_nums;
assert( ~any(isnan(fname_nums)) );

labs = fcat();
evts = [];

for i = 1:numel(days)
  shared_utils.general.progress( i, numel(days) );
  
  day_ind = strcmp( fname_days, days{i} );
  day_files = t_mats(day_ind);
  day_nums = fname_nums(day_ind);
  [~, sort_ind] = sort( day_nums );
  
  day_files = day_files(sort_ind);
  day_nums = day_nums(sort_ind);
  
%   day_files = day_files(1);
%   day_nums = day_nums(1);
  
  day_events = starts(day_I{i}, :);
  day_starts = day_events(:, 1);
  offset = 1;
  
  for j = 1:numel(day_files)
    fprintf( '\n\t %d of %d', j, numel(day_files) );
    
    t_file = shared_utils.io.fload( day_files{j} );
    min_ind = offset;
    max_ind = offset + numel( t_file.t ) - 1;
    offset = max_ind + 1;
    
    is_subset_event = day_starts >= min_ind & day_starts <= max_ind;
    subset_events = day_starts(is_subset_event) - min_ind + 1;
    event_ts = t_file.t(subset_events);
    subset_ind = day_I{i}(is_subset_event);
    
    tmp_f = append( fcat, labels, subset_ind );
    addsetcat( tmp_f, 'unified_filename', t_file.unified_filename );
    append( labs, tmp_f );
    
    evts = [ evts; event_ts ];
  end
end

assert_ispair( evts, labs );

%%

event_file = bfw.load1( 'raw_events' );
joint_events = load( '~/Downloads/cc_joint_event_info_face.mat' );

[event_files, un_I] = bfw_lda.cc_joint_events_to_events_files( ...
  joint_events.evts, joint_events.labs, event_file.params );

intermediate_dir = bfw.gid( 'cc_joint_events-whole_face' );

for i = 1:numel(event_files)
  event_file = event_files{i};
  fname = fullfile( intermediate_dir, event_file.unified_filename );
  save( fname, 'event_file' );
end

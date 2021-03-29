%%  current saved events

events = bfw_gather_events( 'require_stim_meta', false, 'is_parallel', true );

%%  check whether exclusive / mutual event ranges overlap for existing saved events

start_inds = bfw.event_column( events, 'start_index' );
stop_inds = bfw.event_column( events, 'stop_index' );

event_mask = fcat.mask( events.labels, @find, 'eyes_nf' );
check_intersect( start_inds, stop_inds, events.labels, event_mask );

%%  check whether exclusive / mutual event ranges overlap for regenerated events

use_event_outs = event_outs;
% use_event_outs = pre_event_outs;

ok_outs = use_event_outs([use_event_outs.success]);
new_events = cat_expanded( 1, arrayfun(@(x) x.output.events, ok_outs, 'un', 0) );
new_labs = cat_expanded( 1, [{fcat} ...
  ; arrayfun(@(x) addsetcat(fcat.from(x.output), 'unified_filename', x.output.unified_filename) ...
  , ok_outs, 'un', 0)] );
assert_ispair( new_events, new_labs );

start_inds = new_events(:, 1);
stop_inds = new_events(:, 2);

check_intersect( start_inds, stop_inds, new_labs, rowmask(new_labs) )

%%

function check_intersect(start_inds, stop_inds, labels, mask)

assert_ispair( start_inds, labels );
assert_ispair( stop_inds, labels );

run_I = findall( labels, 'unified_filename', mask );

for i = 1:numel(run_I)  
  shared_utils.general.progress( i, numel(run_I) );
  
  mut_ind = find( labels, 'mutual', run_I{i} );
  m1_ind = find( labels, 'm1', run_I{i} );
  m2_ind = find( labels, 'm2', run_I{i} );
  
  m1r = arrayfun( @(x) start_inds(x):stop_inds(x), m1_ind, 'un', 0 );
  m2r = arrayfun( @(x) start_inds(x):stop_inds(x), m2_ind, 'un', 0 );
  mut = arrayfun( @(x) start_inds(x):stop_inds(x), mut_ind, 'un', 0 );
  
  for j = 1:numel(mut)
    for k = 1:numel(m1r)
      overlapm1 = intersect( mut{j}, m1r{k} );
      assert( mut{j}(1) ~= m1r{k}(1), 'm1-mut starts match' );
      assert( isempty(overlapm1), 'm1-mut ranges overlap' );
    end
    for k = 1:numel(m2r)
      overlapm2 = intersect( mut{j}, m2r{k} );
      assert( mut{j}(1) ~= m2r{k}(1), 'm2-mut starts match' );
      assert( isempty(overlapm2), 'm2-mut ranges overlap' );
    end
  end
end

end
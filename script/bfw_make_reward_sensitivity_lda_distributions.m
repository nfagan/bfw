function [x, y, labels] = bfw_make_reward_sensitivity_lda_distributions(sens_perf, sens_labels, lda_perf, lda_labels)

assert_ispair( sens_perf, sens_labels );
assert_ispair( lda_perf, lda_labels );

sens_each = { 'event-name', 'session', 'unit_uuid' };
lda_each = { 'shuffled-type', 'roi' };

[sens_labs, sens_I, sens_C] = keepeach( sens_labels', sens_each );

if ( ~isempty(sens_I) )
  assert( max(cellfun(@numel, sens_I)) == 1, 'Not all combinations were specified.' );
end

labels = fcat();
x = [];
y = []; % don't know size in advance.

for i = 1:numel(sens_I)
  sens_combs = sens_C(:, i);
  current_x = sens_perf(sens_I{i});
  
  % Find matching session and unit uuid, ignoring event-name, since lda
  % doens't have one.
  matches_lda = find( lda_labels, sens_combs(2:3) );
%   assert( ~isempty(matches_lda) );

  if ( isempty(matches_lda) )
    % Lda does not have this unit-session combination.
    continue;
  end
  
  [lda_labs, lda_I] = keepeach( lda_labels', lda_each, matches_lda );
  
  % One row for each combination
  assert( numel(lda_I) == numel(matches_lda) );
  repeated_y = [];
  
  for j = 1:numel(lda_I)
    repeated_y = [ repeated_y; lda_perf(lda_I{j}) ];
  end
  
  repeated_x = repmat( current_x, numel(lda_I), 1 );
  
  x = [ x; repeated_x ];
  y = [ y; repeated_y ];
  
  join( lda_labs, sens_labs(i) );
  append( labels, lda_labs );
end

end
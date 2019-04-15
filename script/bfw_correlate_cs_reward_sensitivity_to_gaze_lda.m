function bfw_correlate_cs_reward_sensitivity_to_gaze_lda(sens_perf, sens_labels, lda_perf, lda_labels, varargin)

assert_ispair( sens_perf, sens_labels );
assert_ispair( lda_perf, lda_labels );

sens_each = { 'event-name', 'session', 'unit_uuid' };
lda_each = { 'shuffled-type', 'roi' };

[sens_I, sens_C] = findall( sens_labels, sens_each );

for i = 1:numel(sens_I)
  sens_combs = sens_C(:, i);
  
  matches_lda = find( lda_labels, sens_combs(2:3) );
end

end
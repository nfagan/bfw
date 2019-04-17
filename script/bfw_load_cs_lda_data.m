function lda = bfw_load_cs_lda_data(lda_file, conf)

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
end

lda_out = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_lda', lda_file) );

shuff_ind = find( lda_out.labels, 'shuffled' );
lda_out.performance(shuff_ind, 3) = 0;

[diffs, diff_labels, I] = dsp3.summary_binary_op( lda_out.performance, lda_out.labels' ...
  , {'unit_uuid', 'session', 'roi'}, 'non-shuffled', 'shuffled', @minus, @identity );

ns = unique( cellfun(@numel, I) );
assert( numel(ns) == 1 && ns == 2 );

any_missing = cellfun( @(x) any(lda_out.performance(x, 2)), I );
diffs(any_missing, :) = nan;

lda = struct();
lda.raw_perf = lda_out.performance;
lda.raw_perf_labels = lda_out.labels;
lda.diff_perf = diffs;
lda.diff_labels = diff_labels;

end
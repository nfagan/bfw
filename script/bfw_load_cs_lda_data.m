function lda = bfw_load_cs_lda_data(lda_file, conf)

if ( nargin < 2 || isempty(conf) )
  conf = bfw.config.load();
end

lda_out = shared_utils.io.fload( fullfile(bfw.dataroot(conf) ...
  , 'analyses/spike_lda', lda_file) );

% Rename regions like 'acc1', 'acc2' -> 'acc', etc.
bfw.unify_single_region_labels( lda_out.labels );

% Column 3 is p-value of permutation test. For 'shuffled' rows, this is
% NaN. As a hack, we can preserve the p-value for 'real' rows during the
% real - null subtraction below if we set the shuffled ps to 0.
shuff_ind = find( lda_out.labels, 'shuffled' );
lda_out.performance(shuff_ind, 3) = 0;

[diffs, diff_labels, I] = dsp3.summary_binary_op( lda_out.performance, lda_out.labels' ...
  , {'unit_uuid', 'session', 'roi'}, 'non-shuffled', 'shuffled', @minus, @identity );

shuff_cat = whichcat( lda_out.labels, 'shuffled' );
setcat( diff_labels, shuff_cat, 'real-null' );

ns = unique( cellfun(@numel, I) );
assert( numel(ns) == 1 && ns == 2 );

% Column 2 indicates whether a model had missing data. If either real or
% null had missing, set the real-null row to NaN.
any_missing = cellfun( @(x) any(lda_out.performance(x, 2)), I );
diffs(any_missing, :) = nan;

lda = struct();
lda.performance = [ lda_out.performance; diffs ];
lda.labels = append( lda_out.labels, diff_labels );

end
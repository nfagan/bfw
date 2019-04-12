function bfw_run_roi_pair_spike_lda()

conf = bfw.config.load();

lda_out = bfw_roi_pair_spike_lda( ...
    'null_iters', 100 ...
  , 'min_t', 0 ...
  , 'max_t', 400 ...
  , 'is_parallel', true ...
  , 'config', conf ...
);

save_p = fullfile( bfw.dataroot(conf), 'analyses', 'spike_lda', dsp3.datedir );
shared_utils.io.require_dir( save_p );

save( fullfile(save_p, 'lda_out.mat'), 'lda_out' );

end

% %%
% 
% I = findall( lda_out.labels, {'unit_uuid', 'unified_filename', 'roi'} );
% 
% real_diffs = nan( numel(I), 1 );
% 
% for i = 1:numel(I)
%   real_ind = find( lda_out.labels, 'non-shuffled', I{i} );
%   shuff_ind = find( lda_out.labels, 'shuffled', I{i} );
%   
%   real_p = lda_out.percent_correct(real_ind, 1);
%   shuff_p = lda_out.percent_correct(shuff_ind, 1);
%   
%   real_diffs(i) = real_p - shuff_p;
% end
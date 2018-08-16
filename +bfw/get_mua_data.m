function psth = get_mua_data( data, ndevs )

%   GET_MUA_DATA -- Convert voltage data to logical data.
%
%     data = dsp2.process.spike.get_mua_psth( data, 3 ) converts the trials
%     x samples data in `data` to trials x spike data in `data`. A 3
%     standard-deviation threshold is used to determine spikes.
%
%     IN:
%       - `data` (double)
%       - `ndevs` (double)
%     OUT:
%       - `psth` (SignalContainer)

N = size( data, 2 );

devs = std( data, [], 2 );
means = mean( data, 2 );
thresh1 = means - (devs .* ndevs);
thresh2 = means + (devs .* ndevs);

thresh1 = repmat( thresh1, 1, N );
thresh2 = repmat( thresh2, 1, N );

psth = data < thresh1 | data > thresh2;

end
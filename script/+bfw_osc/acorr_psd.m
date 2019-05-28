function [f, psd] = acorr_psd(acorr)

sfcoh_defaults = bfw.make.defaults.raw_sfcoherence();
chronux_params = sfcoh_defaults.chronux_params;

[psd, f] = mtspectrumc( acorr, chronux_params );
psd = psd(:);
f = f(:);

end
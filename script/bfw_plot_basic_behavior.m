conf = bfw.config.load();

session_types = bfw.get_sessions_by_stim_type( conf, 'cache', true );

evt_outs = bfw_basic_behavior( ...
    'config', conf ...
  , 'files_containing', session_types.no_stim_sessions ...
);

events = evt_outs.events;
event_key = evt_outs.event_key;
evtlabs = evt_outs.labels';

plot_p = fullfile( bfw.dataroot, 'plots', 'behavior', datestr(now, 'mmddyy') );

%% durations + n fix

evt_durations = events(:, event_key('duration'));

count_spec = { 'session', 'roi', 'looks_by' };

[meanlabs, I] = keepeach( evtlabs', count_spec );

meandur = rownanmean( evt_durations, I );
totaldur = rowop( evt_durations, I, @(x) sum(x, 1, 'omitnan') );
nfix = rowop( evt_durations, I, @(x) nnz(~isnan(x)) );

measdat = [ meandur; totaldur; nfix ];
measlabs = repset( addcat(meanlabs', 'measure'), 'measure' ...
  , {'mean-duration', 'total-duration', 'n-fixations'} );

%%

do_save = true;

pltlabs = measlabs';
pltdat = measdat;

mask = fcat.mask( pltlabs ...
  , @find, {'eyes_nf', 'face', 'mouth'} ...
);

xcats = { 'roi' };
gcats = { 'looks_by' };
pcats = { 'measure' };
fcats = { 'measure' };

pl = plotlabeled.make_common();
pl.group_order = { 'mutual', 'm1', 'm2' };
pl.x_order = { 'eyes_nf', 'mouth' };

pltlabs = pltlabs(mask);
pltdat = pltdat(mask);

[fs, axs, I] = pl.figures( @bar, pltdat, pltlabs, fcats, xcats, gcats, pcats );

for i = 1:numel(fs)
  if ( do_save )
    dsp3.req_savefig( fs(i), plot_p, prune(pltlabs(I{i})), cshorzcat(fcats, pcats), 'fix_info' );
  end
end

%% percentages

uselabs = evtlabs';

p_spec = { 'unified_filename', 'roi', 'looks_by' };

mask = fcat.mask( uselabs, @find, 'mutual' );

I = findall( uselabs, p_spec, mask );

initlabs = fcat();
termlabs = fcat();

initstp = 1;
termstp = 1;

pinit = [];
pterm = [];

init_kinds = combs( uselabs, 'initiator' );
term_kinds = combs( uselabs, 'terminator' );

n_init_kinds = numel( init_kinds );
n_term_kinds = numel( term_kinds );

count_func = @(x, N, ind) double(count(uselabs, x, ind)) / N;

for i = 1:numel(I)
  
  N = numel( I{i} );
  
  c_pinit = cellfun( @(x) count_func(x, N, I{i}), init_kinds );
  c_pterm = cellfun( @(x) count_func(x, N, I{i}), term_kinds );
  
  append1( initlabs, uselabs, I{i}, numel(init_kinds) );
  setcat( initlabs, 'initiator', init_kinds, initstp:initstp+n_init_kinds-1 );
  
  append1( termlabs, uselabs, I{i}, numel(term_kinds) );
  setcat( termlabs, 'terminator', term_kinds, termstp:termstp+n_term_kinds-1 );
  
  pinit = [ pinit; c_pinit(:) ];
  pterm = [ pterm; c_pterm(:) ];
  
  initstp = initstp + n_init_kinds;
  termstp = termstp + n_term_kinds;
end

pdat = [ pinit; pterm ];

plabs = append( initlabs', termlabs );

addsetcat( plabs, 'measure', 'p-initiated', 1:rows(initlabs) );
setcat( plabs, 'measure', 'p-terminated', rows(initlabs)+1:rows(plabs) );
prune( plabs );

assert_ispair( pdat, plabs );

%%  percentages

do_save = true;

pltlabs = plabs';
pltdat = pdat;

mask = fcat.mask( pltlabs ...
  , @find, {'eyes_nf', 'face', 'mouth'} ...
  , @find, 'p-initiated' ...
);

xcats = { 'roi' };
gcats = { 'looks_by', 'initiator' };
pcats = { 'measure' };
fcats = {};

pl = plotlabeled.make_common();
pl.fig = figure(1);
pl.group_order = { 'mutual', 'm1', 'm2' };
pl.x_order = { 'eyes_nf', 'mouth' };

pl.bar( pltdat(mask), pltlabs(mask), xcats, gcats, pcats );

% [fs, axs] = pl.figures( @bar, pltdat(mask), pltlabs(mask), fcats, xcats, gcats, pcats );

if ( do_save )
  dsp3.req_savefig( pl.fig, plot_p, prune(pltlabs(mask)), cshorzcat(fcats, pcats), 'percentages' );
end
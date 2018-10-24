function bfw_aligned_lfp_pipeline(varargin)

%   BFW_ALIGNED_LFP_PIPELINE -- Make lfp-related data, aligned to events.

bfw.make_raw_aligned_lfp( varargin{:} );

bfw.make_raw_coherence( varargin{:} );
bfw.make_raw_mtpower( varargin{:} );

bfw.make_raw_summarized_measure( varargin{:}, 'measure', 'raw_coherence' );
bfw.make_raw_summarized_measure( varargin{:}, 'measure', 'raw_mtpower' );

end
"""
Struct holding the parameters needed at runtime in number format NF.
"""
Base.@kwdef struct Constants{NF<:AbstractFloat} <: AbstractConstants{NF}

    # PHYSICAL CONSTANTS
    radius_earth::NF        # Radius of Earth
    rotation_earth::NF      # Angular frequency of Earth's rotation
    gravity::NF             # Gravitational acceleration
    R_dry::NF               # specific gas constant for dry air [J/kg/K]
    layer_thickness::NF     # shallow water layer thickness [m]
    μ_virt_temp::NF         # used for virt temp calculation
    κ::NF                   # = R_dry/cₚ, gas const for air over heat capacity

    # TIME STEPPING
    Δt::NF                  # time step [s/m], use 2Δt for leapfrog, scaled by Earth's radius
    Δt_unscaled::NF         # time step [s], as Δt but not scaled with Earth's radius
    Δt_sec::Int             # time step [s] but encoded as 64-bit integer for rounding error-free accumulation
    Δt_hrs::Float64         # time step [hrs]
    robert_filter::NF       # Robert (1966) time filter coefficient to suppress comput. mode
    williams_filter::NF     # Williams time filter (Amezcua 2011) coefficient for 3rd order acc
    n_timesteps::Int        # number of time steps to integrate for

    # OUTPUT TIME STEPPING
    output_every_n_steps::Int   # output every n time steps
    n_outputsteps::Int          # total number of output time steps

    # DIFFUSION AND DRAG
    drag_strat::NF              # drag [1/s] for zonal wind in the stratosphere

    # INTERFACE FORCING
    interface_relax_time::NF    # time scale [1/s] for interface relaxation 

    # PARAMETRIZATIONS
    # Large-scale condensation (occurs when relative humidity exceeds a given threshold)
    RH_thresh_pbl_lsc::NF    # Relative humidity threshold for LSC in PBL
    RH_thresh_range_lsc::NF  # Vertical range of relative humidity threshold
    RH_thresh_max_lsc ::NF   # Maximum relative humidity threshold
    humid_relax_time_lsc::NF # Relaxation time for humidity (hours)

    # Convection
    pres_thresh_cnv::NF            # Minimum (normalised) surface pressure for the occurrence of convection
    RH_thresh_pbl_cnv::NF          # Relative humidity threshold for convection in PBL
    RH_thresh_trop_cnv::NF         # Relative humidity threshold for convection in the troposphere
    humid_relax_time_cnv::NF       # Relaxation time for PBL humidity (hours)
    max_entrainment::NF            # Maximum entrainment as a fraction of cloud-base mass flux
    ratio_secondary_mass_flux::NF  # Ratio between secondary and primary mass flux at cloud-base
end

"""
Generator function for a Constants struct.
"""
function Constants(P::Parameters)

    # PHYSICAL CONSTANTS
    @unpack radius_earth, rotation_earth, gravity, R_dry, R_vapour, cₚ = P
    @unpack layer_thickness = P
    H₀ = layer_thickness*1000       # ShallowWater: convert from [km]s to [m]
    ξ = R_dry/R_vapour              # Ratio of gas constants: dry air / water vapour [1]
    μ_virt_temp = (1-ξ)/ξ           # used in Tv = T(1+μq), for conversion from humidity q
                                    # and temperature T to virtual temperature Tv
    κ = R_dry/cₚ                    # = 2/7ish for diatomic gas

    # TIME INTEGRATION CONSTANTS
    @unpack robert_filter, williams_filter = P
    @unpack trunc, Δt_at_T31, n_days, output_dt = P

    # PARAMETRIZATION CONSTANTS
    @unpack RH_thresh_pbl_lsc, RH_thresh_range_lsc, RH_thresh_max_lsc, humid_relax_time_lsc = P  # Large-scale condensation
    @unpack pres_thresh_cnv, RH_thresh_pbl_cnv, RH_thresh_trop_cnv, humid_relax_time_cnv, max_entrainment, ratio_secondary_mass_flux = P  # Convection

    Δt_min_at_trunc = Δt_at_T31*(31/trunc)      # scale time step Δt to specified resolution
    Δt      = round(Δt_min_at_trunc*60)         # convert time step Δt from minutes to whole seconds
    Δt_sec  = convert(Int,Δt)                   # encode time step Δt [s] as integer
    Δt_hrs  = Δt/3600                           # convert time step Δt from minutes to hours
    n_timesteps = ceil(Int,24*n_days/Δt_hrs)    # number of time steps to integrate for
    output_every_n_steps = max(1,floor(Int,output_dt/Δt_hrs))   # output every n time steps
    n_outputsteps = (n_timesteps ÷ output_every_n_steps)+1      # total number of output time steps

    # stratospheric drag [1/s] from damping_time_strat [hrs]
    @unpack damping_time_strat = P
    drag_strat = 1/(damping_time_strat*3600)

    # interface relaxation forcing
    @unpack interface_relax_time = P
    interface_relax_time *= 3600/radius_earth   # convert from hours to seconds

    # SCALING
    Δt_unscaled = Δt        # [s] not scaled
    Δt /= radius_earth      # [s/m] scale with Earth's radius

    # This implies conversion to NF
    return Constants{P.NF}( radius_earth,rotation_earth,gravity,R_dry,H₀,μ_virt_temp,κ,
                            Δt,Δt_unscaled,Δt_sec,Δt_hrs,
                            robert_filter,williams_filter,n_timesteps,
                            output_every_n_steps, n_outputsteps,
                            drag_strat, interface_relax_time,
                            RH_thresh_pbl_lsc, RH_thresh_range_lsc,
                            RH_thresh_max_lsc, humid_relax_time_lsc, pres_thresh_cnv,
                            RH_thresh_pbl_cnv, RH_thresh_trop_cnv, humid_relax_time_cnv,
                            max_entrainment, ratio_secondary_mass_flux,
                            )
end

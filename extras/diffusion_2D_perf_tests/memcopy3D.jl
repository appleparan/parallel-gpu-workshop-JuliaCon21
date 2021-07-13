const USE_GPU = true
using ParallelStencil
using ParallelStencil.FiniteDifferences3D
@static if USE_GPU
    @init_parallel_stencil(CUDA, Float64, 3);
else
    @init_parallel_stencil(Threads, Float64, 3);
end

@parallel function copy3D!(T2, T, Ci)
    @all(T2) = @all(T) + @all(Ci);
    return
end

function memcopy3D()
# Numerics
nx, ny, nz = 1024, 1024, 512;                              # Number of gridpoints in dimensions x, y and z
nt  = 300;                                               # Number of time steps

# Array initializations
T   = @zeros(nx, ny, nz);
T2  = @zeros(nx, ny, nz);
Ci  = @zeros(nx, ny, nz);

# Initial conditions
Ci .= 1/2.0;
T  .= 1.7;
T2 .= T;

# Time loop
for it = 1:nt
    if (it == 11) global t0=time(); end  # Start measuring time.
    @parallel copy3D!(T2, T, Ci);
    T, T2 = T2, T;
end
time_s=time()-t0

# Performance
A_eff = (2*1+1)*1/1e9*nx*ny*nz*sizeof(Data.Number);      # Effective main memory access per iteration [GB] (Lower bound of required memory access: T has to be read and written: 2 whole-array memaccess; Ci has to be read: : 1 whole-array memaccess)
t_it  = time_s/(nt-10);                                  # Execution time per iteration [s]
T_eff = A_eff/t_it;                                      # Effective memory throughput [GB/s]
println("time_s=$time_s T_eff=$T_eff");
end

memcopy3D()
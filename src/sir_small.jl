include("../examples/lorenz.jl")
using JLD
function p_y_g_x(a, σ_o)
        term =  log(1/sqrt(2π)/σ_o) 
        return sum(term .- 0.5*a.*a/σ_o/σ_o)
end
function obs(x, σ_o)
    return x .+ σ_o*randn(d)
end
function obs1(x, σ_o)
	return [x[3] + σ_o*randn()]
end

function resample(x, w)
    # multinomial resampling
    cdfw = cumsum(w)
    new_pts = similar(x)
	N_p = size(w)[1]
    for j = 1:N_p
        r = rand()
        for i = 1:N_p
            if cdfw[i] >= r
                new_pts[:,j] .= x[:,i]
                break
            end
        end
    end
    return new_pts
end

function sir(y,x_ip,Δ,obs_fun,σ_o,σ_d,N_thr=10)
    K = size(y)[2]
    N_p = size(x_ip)[2]
    
    N_y = K*Δ
	@show N_y
	w_trj = zeros(N_p, N_y)
    x_trj = zeros(d, N_p, N_y)


    w = ones(N_p)./N_p
    x = copy(x_ip)
	count = 0
	j = 1
    for k = 1:N_y
        if k % Δ == 0
		    for i = 1: N_p 
                logwi = log(w[i]) + p_y_g_x(y[:,j] .- obs_fun(x[:,i],σ_o), σ_o)
                w[i] = exp(logwi)
			end
            w ./= sum(w)
            N_eff = 1.0/sum(w.*w)
            if (N_eff < N_thr)
				count = count + 1
			    x .= resample(x, w)
		    end
			j = j + 1
		end
        for i = 1:N_p
            x[:,i] .= next(x[:,i],σ_d)
        end
        x_trj[:,:,k] .= x
        w_trj[:,k] .= w
    end
	@show "Resampling was triggered ", count, " times out of ", N_y
    return x_trj, w_trj
end
"""
    assimilate(K, Np, σ_o, σ_d, 
				   Δ, Nth)

Perform `K` data assimilation steps using an SIR algorithm with `Np` particles. Other inputs:

    1. `σ_o`: std of Gaussian observation noise
	2. `σ_d`: std of Gaussian dynamics noise, which is added to every component and at every timestep.
	3. `Δ`: inter-observation number of timesteps, e.g., if `Δ = 5,` observations are assumed available at timestep `0,5,10,...,5(K-1)`.
	4. `Nth`: number of particles below which to resample
	5. `obs`: observation map, e.g., `obs(x) = x[3]`

Outputs:

    1. `x`: orbit of particles. size: `dX x Np x (Δ K)`
	2. `w`: orbit of weights. size: `Np x (Δ K)`
	3. `y`: synthetic observations. size: `dY x K` 
	4. `x_true`: ``true'' orbit that generated the observations. size: `dX x (Δ K)` 

# Examples
```julia-repl
julia> x, w, y, x_true = assimilate(500, 1000, 0.1, 0.1, 1, 10, obs)
```
"""
function assimilate(K, Np, σ_o, σ_d, 
				   Δ, Nth, obsfun)
    x = rand(d,Np)
	Ny = K*Δ
	
	ytest = obsfun(rand(d),σ_o)
	dy = size(ytest)[1]
    x_true = ones(d,Ny)
    x0_true = rand(d)
    Nrunup = 2000
    for i = 1:Nrunup
        x0_true = next(x0_true, 0.0)
    end
    for i = 1:Nrunup
        for j = 1:Np
            x[:,j] = next(x[:,j],σ_d)
        end
    end
    x_true[:,1] .= x0_true
    y = zeros(dy, K)
	y[:,1] .= obsfun(x0_true, σ_o) 
	k = 1
    for i = 2:Ny
        x_true[:,i] = next(x_true[:,i-1], σ_d)
		if i % Δ == 0
        	y[:,k] .= obsfun(x_true[:,i], σ_o)
			k = k+1
		end
    end
    # store trajectory of w and x.
    x_trj, w_trj = sir(y, x, Δ, obsfun, σ_o, σ_d, Nth) 
    return x_trj, w_trj, y, x_true 
end





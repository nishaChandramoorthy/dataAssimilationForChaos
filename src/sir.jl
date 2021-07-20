include("../examples/lorenz.jl")
using JLD
σ_o = 0.1
function p_y_g_x(a)
		return log(1/sqrt(2π)/σ_o) -0.5*a*a/σ_o/σ_o
end
function obs(x)
	return x[3]
end
function sir(y,x_ip,s,N_thr=10)
	K = size(y)[1]
	N_p = size(x)[2]
	d = size(x)[1]
	weights = zeros(N_p, K)
	x_trj = zeros(d, N_p, K)


    w = ones(N_p)./N_p
	new_pts = similar(x_ip)
	x = copy(x_ip)
	
	for k = 1:K
    	for i = 1: N_p 
				logwi = log(w[i]) + p_y_g_x(y[k] - obs(x[:,i]))
				w[i] = exp(logwi)
    	end
		@show sum(w)
		w ./= sum(w)
	    N_eff = 1.0/sum(w.*w)
        if (N_eff < N_thr)
	        #resample
            # multinomial resampling
			cdfw = cumsum(w)
			new_pts .= similar(x)
            for j = 1:N_p
			    r = rand()
			    for i = 1:N_p
		    	    if cdfw[i] >= r
					    new_pts[:,j] .= x[:,i]
			            break
			        end
		        end
		    end
			x .= new_pts
	    end
		x .= next.(x,s)
		part_pos[:,:,k] .= x
		weights[:,k] .= w
    end
	return part_pos, weights
end
function assimilate()
    # Often much larger.
	Np = 100
	K = 10
	d = 3
	x = rand(d,Np)
	s = 0.001
	x_true = ones(K)
	x0_true = 2*pi*rand()
	x_true[1] = x0_true
	y = zeros(K)
	for i = 2:K
	    x_true[:,i] = next(x_true[:,i-1], s)
		y[i] = obs(x_true[:,i]) + σ_o*randn()
	end
	N_thr = 20
	# store trajectory of w and x.
	x_trj, w_trj = sir(y, x, s, N_thr) 
	return x_trj, w_trj, x_true  
end



